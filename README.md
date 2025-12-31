
---

# 📘 Automation Reports

## מסמך טכני – אפיון מערכת, מבנה ואופן פעולה

---

## 1. מטרת המערכת (Purpose)

מערכת **Automation Reports** נועדה לספק מנגנון אוטומטי, מאובטח וסטנדרטי להפקה ושליחה של דוחות ובדיקות תקופתיות בסביבת **Microsoft 365**, עם דגש על:

* ניטור ניצול נפח תיבות דואר וארכיון
* בדיקות רישוי ומדיניות שמירה (Retention)
* הפקת דוחות Excel אחידים
* שליחה אוטומטית בדוא״ל
* Audit מלא לכל ריצה (לוגים + Snapshots)
* מינימום התערבות ידנית
* התאמה קלה לסביבות ולקוחות שונים

המערכת בנויה כך שתוכל לשמש גם לדוחות ובדיקות נוספות בעתיד (לא רק 365).

---

## 2. עקרונות תכנון (Design Principles)

* **Entry Point אחד** – סקריפט ריצה מרכזי
* **Pipeline קבוע** – שלבים ברורים ומוגדרים
* **Configuration Driven** – התנהגות המערכת נקבעת ע״י JSON
* **Separation of Concerns** – קוד ≠ תצורה ≠ תוצרים
* **Non-Interactive Authentication** – ללא סיסמאות וללא MFA
* **Auditability מלאה** – כל ריצה ניתנת לשחזור וניתוח
* **Scheduler Agnostic** – זהה ל-Task Scheduler ול-Rundeck

---

## 3. סקירה ארכיטקטונית כללית

המערכת בנויה כ-**Runner אחד** שמפעיל Pipeline מודולרי, עם חיבור יחיד ל-Microsoft 365 וכתיבת תוצרים ל-Working Directory מקומי.

### רכיבים עיקריים

* Runner (Run.ps1)
* מודולי לוגיקה (PowerShell Modules)
* קבצי תצורה (JSON)
* תיבת דוא״ל ייעודית לשליחה
* סביבת אחסון תוצרים (Logs / Snapshots / Reports)
* Git Repository (לקוד בלבד)

---

## 4. תרשים סכמטי – מבנה המערכת

```
┌───────────────────────────┐
│   Scheduler / Trigger     │
│ (Task Scheduler / Rundeck)│
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│        Run.ps1             │
│   (Entry Point / Runner)   │
└─────────────┬─────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│              Pipeline                    │
│                                         │
│  Preflight + Auth                        │
│  Data Collection                         │
│  Normalization                           │
│  Calculations                            │
│  Recommendation Engine                  │
│  Report Rendering (XLSX)                │
│  Email Delivery                          │
│  Post-Run                               │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│     Working Directory (Server)           │
│                                         │
│  runs/      → logs + snapshots + output │
│  archive/   → reports only              │
└─────────────────────────────────────────┘
              │
              ▼
┌───────────────────────────┐
│ Microsoft 365              │
│ - Exchange Online          │
│ - Microsoft Graph          │
└───────────────────────────┘
```

---

## 5. אופן האותנטיקציה (Authentication Model)

### מודל

**Azure App Registration + Certificate Authentication**

### עקרונות

* אין שימוש בסיסמאות
* אין MFA
* Private Key נשמר רק בשרת הריצה
* Public Key נשמר ב-App Registration

### שירותים

* Exchange Online (קריאה לנתוני תיבות)
* Microsoft Graph (רישוי + שליחת מייל)

---

## 6. תיבת שליחה ייעודית

* כתובת:
  `automation-reports@<domain>`
* סוג: Shared Mailbox
* שימוש:

  * שליחת דוחות ובדיקות אוטומטיות
  * שמירת כל הודעה ב-Sent Items
* שליחה מתבצעת דרך Microsoft Graph (`saveToSentItems = true`)

---

## 7. Pipeline – שלבי הפעולה

1. **Trigger**

   * Task Scheduler / Rundeck
2. **Run Initialization**

   * יצירת RunId
   * פתיחת לוג
   * יצירת תיקיות ריצה
3. **Preflight + Authentication**

   * טעינת Config
   * התחברות ל-M365
4. **Data Collection**

   * Mailbox / Archive
   * רישוי
   * Retention
5. **Normalization**

   * המרות (Bytes → GB)
   * ניקוי נתונים
6. **Calculations**

   * חישוב נפח פנוי
   * חישוב אחוזים
   * Status (OK / Warning)
7. **Recommendation Engine**

   * המלצה רק במצב חריגה
8. **Report Rendering**

   * יצירת XLSX
   * Sheets + מיון
9. **Email Delivery**

   * שליחה ללקוח
10. **Post-Run**

    * סגירה
    * ארכוב
    * סטטוס ריצה

---

## 8. לוגים ו-Snapshots

### לוג מרכזי

* קובץ: `process.log`
* מכיל:

  * כל שלב
  * שגיאות
  * מדדים
  * זמני ריצה

### Snapshots

* קובץ נפרד לכל שלב
* CSV / JSON
* משקף מצב נתונים לפני מעבר שלב
* מאפשר Debug / Audit / שחזור

---

## 9. מבנה Repository (Git)

```
automation-reports/
├─ README.md
├─ docs/
│  └─ automation-reports-technical-design.md
├─ src/
│  ├─ Run.ps1
│  ├─ Modules/
│  ├─ Templates/
│  └─ Schemas/
├─ config/
│  ├─ environments/*.sample.json
│  ├─ customers/*.sample.json
│  └─ mapping/*.sample.json
├─ tools/
│  └─ Build-Release.ps1
└─ .gitignore
```

**ה-Repo מכיל קוד בלבד – לא תוצרים ולא נתוני אמת.**

---

## 10. מבנה Working Directory (שרת ריצה)

```
D:\AutomationReports\
├─ app\        ← קוד פרוס (מה-Repo / ZIP)
├─ config\     ← קונפיג פרודקשן
├─ runs\       ← תוצרים תפעוליים (logs, snapshots, output)
└─ archive\    ← דוחות סופיים ללקוח
```

---

## 11. עבודה עם Git ובלי Git

* Git משמש לפיתוח, גרסאות ותחזוקה
* בפרודקשן ניתן לעבוד:

  * עם Git Pull
  * או עם **Release ZIP** (ללא חיבור ל-Git)
* הקוד זהה – רק אופן הפריסה משתנה

---

## 12. אבטחה ובקרות

* אין Credentials בקוד או ב-JSON
* Private Key מוגן ע״י OS
* Audit כפול:

  * לוגים
  * Sent Items בתיבת הדוחות
* ניתן להקשיח הרשאות App לפי צורך

---

## 13. סיכום

מערכת **Automation Reports** היא מערכת אוטומציה ארגונית מלאה, המספקת:

* סטנדרטיזציה
* אבטחה
* שקיפות
* Scalability
* שימוש חוזר לבדיקות עתידיות

המערכת תוכננה כך שתתאים הן לארגונים קטנים והן לסביבות Enterprise עם כלי Orchestration מתקדמים.

---
