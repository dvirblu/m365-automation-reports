מצוין.
להלן **סיכום סופי, אחיד ומסודר** של כל התהליך כפי שנבנה עד כה – מרמת הארכיטקטורה ועד אופן העבודה עם Git ופריסה ללא Git.
זהו מסמך תפיסתי מלא, שאפשר להישען עליו לפיתוח, פריסה ותפעול.

---

# 🧭 סיכום כולל – מערכת Automation Reports

## 🎯 מטרת המערכת

מערכת אוטומטית אחת שמבצעת **בדיקות ודוחות תקופתיים** (365 ובהמשך נוספים), ומפיקה:

* דוח מלא (כולל תקינים וחריגים)
* המלצות חכמות רק כשנדרש
* Audit מלא (לוגים + snapshots)
* שליחה אוטומטית בדוא״ל
* מינימום התערבות ידנית
* התאמה קלה לסביבות שונות

---

## 📨 תיבת שליחה ייעודית

**שם:**

```
automation-reports@<domain>
```

**סוג:**

* Shared Mailbox (תיבה אמיתית ב-Exchange Online)

**שימוש:**

* שליחת דוחות ובדיקות אוטומטיות מכל הסוגים
* כל מייל נשמר ב־Sent Items (`saveToSentItems = true`)
* מאפשר Audit, Troubleshooting ושקיפות

❌ אין פיברוק כתובת
❌ אין SMTP חיצוני

---

## 🔐 אותנטיקציה ואבטחה

### מודל התחברות

**App Registration + Certificate Authentication**

* **Private Key**

  * נשמר על מחשב/שרת הריצה (Certificate Store / Key Vault)
* **Public Key**

  * נשמר ב-App Registration ב-Entra ID

📌 אין סיסמאות
📌 אין MFA
📌 אין Secrets בקוד או ב-JSON

### הרשאות עיקריות

* Exchange Online – קריאה לנתוני Mailbox / Archive / Retention
* Microsoft Graph:

  * `Directory.Read.All`
  * `Mail.Send`
* Admin Consent חד-פעמי

---

## 🧠 מבנה ריצה (Run)

**Run = ריצה אחת מבודדת של המערכת**, עם:

* RunId ייחודי
* תיקיות עבודה משלה
* לוג מרכזי אחד
* Snapshots לכל שלב
* תוצר סופי אחד (XLSX)

אין חפיפה בין ריצות.

---

## 🔄 Pipeline – שלבי התהליך

1. Trigger / Scheduler
2. Preflight + Authentication
3. Data Collection
4. Normalization
5. Calculations
6. Recommendation Engine
7. Sanity / QA
8. Report Rendering (XLSX)
9. Email Delivery
10. Post-Run & Cleanup

📌 לפני כל מעבר שלב → נכתב Snapshot + Log

---

## 🪵 לוגים ו־Snapshots

### לוג מרכזי

* `process.log`
* נכתב לאורך כל הריצה
* כולל:

  * התחלה/סיום שלבים
  * סטטיסטיקות
  * שגיאות ואזהרות
  * משכי זמן

### Snapshots

* קובץ נפרד לכל שלב (CSV / JSON)
* מתעדים “מצב נתונים”
* מאפשרים Debug / Audit / שחזור
* לא מכילים Secrets

---

## 📄 תפקיד קבצי JSON

ה־JSON הוא מה שהופך את הקוד ל־**אוניברסלי**:

* `config.json`

  * מגדיר *איך* המערכת רצה (ספים, נתיבים, נמענים, תיבה שולחת)
  * שינוי מדיניות ללא שינוי קוד

* Snapshots (`*.json`)

  * תיעוד מצב ביניים
  * לא מבצעים לוגיקה

📌 קוד = Engine
📌 JSON = Configuration / State

---

## 📦 מבנה קוד (רמה פיזית)

### Entry Point אחד

* `Run.ps1`

### מודולים (כ־10–11 קבצים)

* Config
* Logging
* Snapshot
* Auth
* DataCollection
* Normalization
* Calculation
* Recommendation
* Rendering
* Delivery

📌 מבחוץ: “סקריפט אחד”
📌 מבפנים: מערכת מודולרית

---

## 🗂️ עבודה עם Git – ומה לא נכנס ל-Git

### Git Repository (יחיד)

* קוד
* תבניות
* config לדוגמה (`_sample`)
* סכמות
* תיעוד

❌ לא כולל:

* דוחות
* לוגים
* snapshots
* config אמיתי
* נתוני אמת
* credentials

Git = **Source of Truth לקוד בלבד**

---

## 🖥️ Working Directory (לא Git)

על שרת הריצה בלבד:

```
D:\AutomationReports\
├─ app\        (קוד פרוס)
├─ config\     (קונפיג אמיתי)
├─ runs\       (תוצרים תפעוליים)
└─ archive\    (דוחות סופיים)
```

---

## 🔁 עבודה עם Git + בלי Git

### מודל עבודה

* פיתוח וניהול גרסאות → Git
* פריסה ליעדים:

  * עם Git → `git pull`
  * בלי Git → **Release ZIP (אופליין)**

### Release ZIP כולל:

* `Run.ps1`
* `Modules\`
* `Templates\`
* `Schemas\`
* `VERSION.txt`

❌ לא כולל:

* config אמיתי
* outputs
* credentials

---

## 🟢 השורה התחתונה

בנינו:

> **מערכת אוטומציה ארגונית**
> ולא סקריפט חד-פעמי

עם:

* זהות מאובטחת
* הפרדת קוד / נתונים / תוצרים
* תמיכה מלאה ב-Git וגם בפריסה אופליין
* Audit מלא
* Scalability לבדיקות עתידיות

---

## 🔜 הצעד הבא (לבחירתך)

1. 🧾 מבנה `config.json` סופי
2. 🧱 Skeleton קוד (קבצים + פונקציות ריקות)
3. 🔐 Checklist אבטחה ו-Go-Live
4. 📦 מבנה Release ZIP + Runbook פריסה

תגיד לאן אתה רוצה להתקדם.
