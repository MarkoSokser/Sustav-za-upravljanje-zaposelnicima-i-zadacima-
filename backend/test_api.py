"""
Backend API Test Script
Automatsko testiranje svih endpointa
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8000"
API = f"{BASE_URL}/api"

# Boje za terminal output
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
RESET = "\033[0m"

def print_test(name, passed, details=""):
    status = f"{GREEN}✓ PASS{RESET}" if passed else f"{RED}✗ FAIL{RESET}"
    print(f"  {status} - {name}")
    if details and not passed:
        print(f"         {YELLOW}{details}{RESET}")

def print_section(name):
    print(f"\n{BLUE}{'='*60}{RESET}")
    print(f"{BLUE}  {name}{RESET}")
    print(f"{BLUE}{'='*60}{RESET}")

# Statistike
tests_passed = 0
tests_failed = 0

def run_test(name, condition, details=""):
    global tests_passed, tests_failed
    if condition:
        tests_passed += 1
    else:
        tests_failed += 1
    print_test(name, condition, details)
    return condition

# ============================================================
# TEST 1: Health Check
# ============================================================
print_section("1. HEALTH CHECK")

try:
    r = requests.get(f"{BASE_URL}/")
    run_test("Root endpoint dostupan", r.status_code == 200)
    run_test("Verzija API-ja prisutna", "version" in r.json())
except Exception as e:
    run_test("Root endpoint", False, str(e))

try:
    r = requests.get(f"{BASE_URL}/health")
    run_test("Health endpoint", r.status_code == 200)
    data = r.json()
    run_test("Database healthy", data.get("database") == "healthy")
except Exception as e:
    run_test("Health endpoint", False, str(e))

# ============================================================
# TEST 2: Authentication
# ============================================================
print_section("2. AUTENTIKACIJA")

# Login s admin korisnikom
token = None
try:
    r = requests.post(f"{API}/auth/login", data={
        "username": "admin",
        "password": "Admin@123"
    })
    run_test("Admin login", r.status_code == 200)
    if r.status_code == 200:
        token = r.json().get("access_token")
        run_test("Token dobiven", token is not None)
except Exception as e:
    run_test("Admin login", False, str(e))

# Login s pogrešnom lozinkom
try:
    r = requests.post(f"{API}/auth/login", data={
        "username": "admin",
        "password": "wrongpassword"
    })
    run_test("Odbijen login s pogrešnom lozinkom", r.status_code == 401)
except Exception as e:
    run_test("Pogrešan login", False, str(e))

# Headers za autentificirane zahtjeve
headers = {"Authorization": f"Bearer {token}"} if token else {}

# Get current user
try:
    r = requests.get(f"{API}/auth/me", headers=headers)
    run_test("GET /auth/me", r.status_code == 200)
    if r.status_code == 200:
        user = r.json()
        run_test("Username je admin", user.get("username") == "admin")
except Exception as e:
    run_test("GET /auth/me", False, str(e))

# Get permissions
try:
    r = requests.get(f"{API}/auth/me/permissions", headers=headers)
    run_test("GET /auth/me/permissions", r.status_code == 200)
    if r.status_code == 200:
        perms = r.json()
        run_test("Admin ima permisije", len(perms) > 0)
except Exception as e:
    run_test("GET /auth/me/permissions", False, str(e))

# Get roles
try:
    r = requests.get(f"{API}/auth/me/roles", headers=headers)
    run_test("GET /auth/me/roles", r.status_code == 200)
    if r.status_code == 200:
        roles = r.json()
        run_test("Admin ima ADMIN ulogu", any(role.get("role_name") == "ADMIN" for role in roles))
except Exception as e:
    run_test("GET /auth/me/roles", False, str(e))

# ============================================================
# TEST 3: Users Management
# ============================================================
print_section("3. KORISNICI")

# Get all users
try:
    r = requests.get(f"{API}/users", headers=headers)
    run_test("GET /users", r.status_code == 200)
    if r.status_code == 200:
        users = r.json()
        run_test("Više korisnika pronađeno", len(users) >= 5)
except Exception as e:
    run_test("GET /users", False, str(e))

# Get user statistics
try:
    r = requests.get(f"{API}/users/statistics", headers=headers)
    run_test("GET /users/statistics", r.status_code == 200)
except Exception as e:
    run_test("GET /users/statistics", False, str(e))

# Get single user
try:
    r = requests.get(f"{API}/users/1", headers=headers)
    run_test("GET /users/1", r.status_code == 200)
    if r.status_code == 200:
        user = r.json()
        run_test("User ID 1 je admin", user.get("username") == "admin")
except Exception as e:
    run_test("GET /users/1", False, str(e))

# Get user team
try:
    r = requests.get(f"{API}/users/2/team", headers=headers)
    run_test("GET /users/{id}/team", r.status_code == 200)
except Exception as e:
    run_test("GET /users/{id}/team", False, str(e))

# ============================================================
# TEST 4: Tasks Management
# ============================================================
print_section("4. ZADACI")

# Get all tasks
try:
    r = requests.get(f"{API}/tasks", headers=headers)
    run_test("GET /tasks", r.status_code == 200)
    if r.status_code == 200:
        tasks = r.json()
        run_test("Zadaci pronađeni", len(tasks) >= 0)
except Exception as e:
    run_test("GET /tasks", False, str(e))

# Create a new task
new_task_id = None
try:
    r = requests.post(f"{API}/tasks", headers=headers, json={
        "title": "Test zadatak API",
        "description": "Ovo je test zadatak kreiran kroz API",
        "priority": "MEDIUM",
        "status": "PENDING"
    })
    run_test("POST /tasks (kreiranje)", r.status_code in [200, 201])
    if r.status_code in [200, 201]:
        response_data = r.json()
        run_test("Kreiranje uspješno", response_data.get("success") == True)
except Exception as e:
    run_test("POST /tasks", False, str(e))

# Get my task statistics
try:
    r = requests.get(f"{API}/tasks/my/statistics", headers=headers)
    run_test("GET /tasks/my/statistics", r.status_code == 200)
except Exception as e:
    run_test("GET /tasks/statistics", False, str(e))

# Get my tasks
try:
    r = requests.get(f"{API}/tasks/my", headers=headers)
    run_test("GET /tasks/my", r.status_code == 200)
except Exception as e:
    run_test("GET /tasks/my", False, str(e))

# ============================================================
# TEST 5: Roles Management
# ============================================================
print_section("5. ULOGE")

# Get all roles
try:
    r = requests.get(f"{API}/roles", headers=headers)
    run_test("GET /roles", r.status_code == 200)
    if r.status_code == 200:
        roles = r.json()
        run_test("Uloge pronađene", len(roles) >= 3)
        role_names = [role.get("name") for role in roles]
        run_test("ADMIN uloga postoji", "ADMIN" in role_names)
        run_test("MANAGER uloga postoji", "MANAGER" in role_names)
        run_test("EMPLOYEE uloga postoji", "EMPLOYEE" in role_names)
except Exception as e:
    run_test("GET /roles", False, str(e))

# Get permissions
try:
    r = requests.get(f"{API}/roles/permissions", headers=headers)
    run_test("GET /roles/permissions", r.status_code == 200)
    if r.status_code == 200:
        perms = r.json()
        run_test("Permisije pronađene", len(perms) >= 10)
except Exception as e:
    run_test("GET /roles/permissions", False, str(e))

# ============================================================
# TEST 6: Audit Logs
# ============================================================
print_section("6. AUDIT LOGOVI")

# Get audit logs
try:
    r = requests.get(f"{API}/audit/logs", headers=headers)
    run_test("GET /audit/logs", r.status_code == 200)
    if r.status_code == 200:
        logs = r.json()
        run_test("Audit logovi pronađeni", isinstance(logs, list))
except Exception as e:
    run_test("GET /audit/logs", False, str(e))

# Get login events
try:
    r = requests.get(f"{API}/audit/logins", headers=headers)
    run_test("GET /audit/logins", r.status_code == 200)
except Exception as e:
    run_test("GET /audit/logins", False, str(e))

# ============================================================
# TEST 7: Unauthorized Access
# ============================================================
print_section("7. SIGURNOST - NEAUTORIZIRANI PRISTUP")

# Try to access protected endpoint without token
try:
    r = requests.get(f"{API}/users")
    run_test("Odbijen pristup bez tokena", r.status_code == 401)
except Exception as e:
    run_test("Pristup bez tokena", False, str(e))

# Try with invalid token
try:
    r = requests.get(f"{API}/users", headers={"Authorization": "Bearer invalid_token"})
    run_test("Odbijen pristup s nevažećim tokenom", r.status_code == 401)
except Exception as e:
    run_test("Nevažeći token", False, str(e))

# ============================================================
# TEST 8: Login as different users
# ============================================================
print_section("8. RAZLIČITI KORISNICI")

# Login as manager
try:
    r = requests.post(f"{API}/auth/login", data={
        "username": "ivan_manager",
        "password": "Admin@123"
    })
    run_test("Manager login (ivan_manager)", r.status_code == 200)
    if r.status_code == 200:
        manager_token = r.json().get("access_token")
        manager_headers = {"Authorization": f"Bearer {manager_token}"}
        
        # Check manager roles
        r2 = requests.get(f"{API}/auth/me/roles", headers=manager_headers)
        if r2.status_code == 200:
            roles = r2.json()
            run_test("Manager ima MANAGER ulogu", any(role.get("role_name") == "MANAGER" for role in roles))
except Exception as e:
    run_test("Manager login", False, str(e))

# Login as employee
try:
    r = requests.post(f"{API}/auth/login", data={
        "username": "marko_dev",
        "password": "Admin@123"
    })
    run_test("Employee login (marko_dev)", r.status_code == 200)
    if r.status_code == 200:
        emp_token = r.json().get("access_token")
        emp_headers = {"Authorization": f"Bearer {emp_token}"}
        
        # Employee should NOT have access to all users
        r2 = requests.get(f"{API}/users", headers=emp_headers)
        run_test("Employee nema pristup svim korisnicima", r2.status_code == 403)
except Exception as e:
    run_test("Employee login", False, str(e))

# ============================================================
# SUMMARY
# ============================================================
print_section("SAŽETAK")
total = tests_passed + tests_failed
print(f"\n  Ukupno testova: {total}")
print(f"  {GREEN}Prošlo: {tests_passed}{RESET}")
print(f"  {RED}Palo: {tests_failed}{RESET}")
print(f"\n  Postotak uspješnosti: {(tests_passed/total)*100:.1f}%\n")

if tests_failed == 0:
    print(f"  {GREEN}🎉 SVI TESTOVI PROŠLI! Backend je spreman za frontend.{RESET}\n")
else:
    print(f"  {YELLOW}⚠️  Neki testovi nisu prošli. Provjerite greške iznad.{RESET}\n")
