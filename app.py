# app.py
import os
from datetime import date, timedelta
from urllib.parse import quote_plus

from flask import Flask, request, redirect, url_for, render_template, flash
from sqlalchemy import (Column, Integer, String, Date, ForeignKey, Text,
                        SmallInteger, DECIMAL, create_engine, func)
from sqlalchemy.orm import declarative_base, relationship, sessionmaker, scoped_session
from dotenv import load_dotenv

load_dotenv()

# ---------- CONFIG ----------
# Edit these if needed for your environment
SERVER = os.getenv("DB_SERVER", "ANKIT")          # from your SSMS (ANKIT in your screenshot)
DATABASE = os.getenv("DB_NAME", "LibraryDB")
DRIVER = os.getenv("DB_DRIVER", "ODBC Driver 17 for SQL Server")

# Build ODBC connection for Windows Authentication (Trusted Connection)
odbc_str = (
    f"DRIVER={{{DRIVER}}};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    "Trusted_Connection=yes;"
    "Encrypt=no;"
)
connect_uri = "mssql+pyodbc:///?odbc_connect=" + quote_plus(odbc_str)

# ---------- SQLAlchemy ----------
engine = create_engine(connect_uri, fast_executemany=True)
SessionFactory = sessionmaker(bind=engine)
Session = scoped_session(SessionFactory)
Base = declarative_base()

# ---------- MODELS (map to your existing SQL Server tables) ----------
class Publisher(Base):
    __tablename__ = 'Publishers'
    publisher_id = Column(Integer, primary_key=True)
    name = Column(String(255), nullable=False)

class Category(Base):
    __tablename__ = 'Categories'
    category_id = Column(Integer, primary_key=True)
    name = Column(String(200), nullable=False)

class Book(Base):
    __tablename__ = 'Books'
    book_id = Column(Integer, primary_key=True)
    title = Column(String(500), nullable=False)
    isbn = Column(String(50))
    publisher_id = Column(Integer, ForeignKey('Publishers.publisher_id'))
    publication_year = Column(SmallInteger)
    pages = Column(SmallInteger)
    language = Column(String(100))
    category_id = Column(Integer, ForeignKey('Categories.category_id'))
    description = Column(Text)

    publisher = relationship('Publisher', lazy='joined')
    category = relationship('Category', lazy='joined')

class Copy(Base):
    __tablename__ = 'Copies'
    copy_id = Column(Integer, primary_key=True)
    book_id = Column(Integer, ForeignKey('Books.book_id'))
    accession_no = Column(String(100))
    location = Column(String(200))
    status = Column(String(50))
    price = Column(DECIMAL(10, 2))

    book = relationship('Book', lazy='joined')

class Member(Base):
    __tablename__ = 'Members'
    member_id = Column(Integer, primary_key=True)
    full_name = Column(String(255), nullable=False)
    email = Column(String(255))

class Staff(Base):
    __tablename__ = 'Staff'
    staff_id = Column(Integer, primary_key=True)
    username = Column(String(100))

class Loan(Base):
    __tablename__ = 'Loans'
    loan_id = Column(Integer, primary_key=True)
    copy_id = Column(Integer, ForeignKey('Copies.copy_id'))
    member_id = Column(Integer, ForeignKey('Members.member_id'))
    staff_id = Column(Integer, ForeignKey('Staff.staff_id'))
    issued_date = Column(Date)
    due_date = Column(Date)
    returned_date = Column(Date)
    status = Column(String(50))
    fine_amount = Column(DECIMAL(10,2))

    copy = relationship('Copy', lazy='joined')
    member = relationship('Member', lazy='joined')

# If you want to create missing tables (only if you don't already have them):
# Base.metadata.create_all(bind=engine)

# ---------- FLASK APP ----------
app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET", "devsecret")

# ---------- Helpers ----------
def to_int(value):
    """Safely convert to int; return None on failure."""
    try:
        if value is None:
            return None
        # strip in case spaces
        if isinstance(value, str):
            value = value.strip()
            if value == "":
                return None
        return int(value)
    except (ValueError, TypeError):
        return None

# ---------- Routes ----------
@app.route("/")
def index():
    session = Session()
    try:
        books = session.query(Book).order_by(Book.title).limit(200).all()
        copies = session.query(Copy).order_by(Copy.copy_id).limit(200).all()
        return render_template("index.html", books=books, copies=copies)
    finally:
        session.close()

@app.route("/add_book", methods=["POST"])
def add_book():
    title = request.form.get("title", "").strip()
    isbn = request.form.get("isbn", "").strip()
    pub_name = request.form.get("publisher", "").strip()
    cat_name = request.form.get("category", "").strip()

    if not title:
        flash("Title is required", "danger")
        return redirect(url_for("index"))

    session = Session()
    try:
        publisher = None
        if pub_name:
            publisher = session.query(Publisher).filter(func.lower(Publisher.name) == pub_name.lower()).first()
            if not publisher:
                publisher = Publisher(name=pub_name)
                session.add(publisher)
                session.flush()

        category = None
        if cat_name:
            category = session.query(Category).filter(func.lower(Category.name) == cat_name.lower()).first()
            if not category:
                category = Category(name=cat_name)
                session.add(category)
                session.flush()

        book = Book(title=title, isbn=isbn,
                    publisher_id=publisher.publisher_id if publisher else None,
                    category_id=category.category_id if category else None)
        session.add(book)
        session.commit()
        flash("Book added.", "success")
    except Exception as e:
        session.rollback()
        flash("Error adding book: " + str(e), "danger")
    finally:
        session.close()
    return redirect(url_for("index"))

@app.route("/members", methods=["GET", "POST"])
def members():
    session = Session()
    try:
        if request.method == "POST":
            name = request.form.get("full_name", "").strip()
            email = request.form.get("email", "").strip()
            if not name:
                flash("Name required", "danger")
                return redirect(url_for("members"))
            m = Member(full_name=name, email=email or None)
            session.add(m)
            session.commit()
            flash("Member added.", "success")
            return redirect(url_for("members"))

        members = session.query(Member).order_by(Member.full_name).limit(500).all()
        return render_template("members.html", members=members)
    finally:
        session.close()

@app.route("/loans", methods=["GET", "POST"])
def loans():
    session = Session()
    try:
        if request.method == "POST":
            action = request.form.get("action")

            # ----- ISSUE -----
            if action == "issue":
                copy_id = to_int(request.form.get("copy_id"))
                member_id = to_int(request.form.get("member_id"))
                loan_days = to_int(request.form.get("loan_days")) or 14

                if copy_id is None or member_id is None:
                    flash("Please select both a copy and a member.", "warning")
                    return redirect(url_for("loans"))

                copy = session.query(Copy).get(copy_id)
                if not copy:
                    flash("Selected copy not found.", "danger")
                    return redirect(url_for("loans"))
                if copy.status != 'available':
                    flash("Selected copy is not available.", "warning")
                    return redirect(url_for("loans"))

                issued = date.today()
                due = issued + timedelta(days=loan_days)
                loan = Loan(copy_id=copy_id, member_id=member_id, staff_id=None,
                            issued_date=issued, due_date=due, status='issued', fine_amount=0)
                copy.status = 'loaned'
                session.add(loan)
                session.commit()
                flash("Issued successfully.", "success")
                return redirect(url_for("loans"))

            # ----- RETURN -----
            if action == "return":
                loan_id = to_int(request.form.get("loan_id"))
                if loan_id is None:
                    flash("No loan selected to return.", "warning")
                    return redirect(url_for("loans"))

                loan = session.query(Loan).get(loan_id)
                if not loan:
                    flash("Loan not found.", "danger")
                    return redirect(url_for("loans"))
                if loan.returned_date:
                    flash("Loan already returned.", "info")
                    return redirect(url_for("loans"))

                loan.returned_date = date.today()
                if loan.due_date and loan.returned_date > loan.due_date:
                    days = (loan.returned_date - loan.due_date).days
                    loan.fine_amount = float(days) * 1.0
                loan.status = 'returned'
                if loan.copy:
                    loan.copy.status = 'available'
                session.commit()
                flash(f"Returned. Fine: {loan.fine_amount or 0}", "success")
                return redirect(url_for("loans"))

        # GET
        loans_list = session.query(Loan).order_by(Loan.loan_id.desc()).limit(200).all()
        available_copies = session.query(Copy).filter(Copy.status == 'available').limit(200).all()
        members = session.query(Member).order_by(Member.full_name).limit(500).all()
        return render_template("loans.html", loans=loans_list, available_copies=available_copies, members=members)
    finally:
        session.close()

# ---------- RUN ----------
if __name__ == "__main__":
    # quick connection test
    try:
        with engine.connect() as conn:
            conn.execute(func.now())
        print("Connected to DB OK.")
    except Exception as ex:
        print("DB connection failed:", ex)
    app.run(debug=True)
