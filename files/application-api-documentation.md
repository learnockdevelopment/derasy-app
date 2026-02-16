# Derasy API Documentation

This documentation provides details on the APIs used for the platform's core workflows: **Parent Admission Applications** and **Sales School Onboarding**. All endpoints are RESTful and use JSON for request and response bodies.

---

## 🔐 Authentication
Most endpoints require authentication via a Bearer Token (JWT).
- **Header**: `Authorization: Bearer <your_token>`
- **Token Source**: Obtained upon login via `/api/auth/login` (or NextAuth session).

---

## 1. Public Lookups & Reference Data
These APIs provide the necessary data to populate dropdown menus (School Types, Locations, Systems, etc.) for both search filters and onboarding forms.

### 1.1 General Lookups (Dropdown Data)
**Endpoint**: `GET /api/public/lookups`
**Use Case**: Fetch static lists for "School Type", "Gender Policy", "Religion", "Special Needs", and dynamic "Facilities".

#### Response Example
```json
{
  "success": true,
  "data": {
    "schoolTypes": [
      { "id": "Private", "label": "المدارس الخاصة", "labelEn": "Private Schools" },
      { "id": "National", "label": "المدارس القومية", "labelEn": "National Schools" }
    ],
    "genderPolicies": [
      { "id": "Mixed", "label": "مشترك" },
      { "id": "Boys", "label": "بنين" },
      { "id": "Girls", "label": "بنات" }
    ],
    "religionTypes": [
      { "id": "None", "label": "عام / غير محدد" },
      { "id": "Muslim", "label": "مسلم" },
      { "id": "Christian", "label": "مسيحي" }
    ],
    "specialNeedsTypes": [
      { "id": "None", "label": "لا يوجد" },
      { "id": "Integration", "label": "سياسة الدمج التعليمي" },
      { "id": "SpecialClasses", "label": "فصول خاصة" },
      { "id": "SpecializedSchool", "label": "مدرسة متخصصة" }
    ],
    "locations": {
      "governorates": [
        { "id": "1", "nameAr": "القاهرة", "nameEn": "Cairo" },
        { "id": "2", "nameAr": "الجيزة", "nameEn": "Giza" }
      ],
      "administrations": {
        "1": [
          { "id": "1", "nameAr": "15 مايو", "nameEn": "15 May" }
        ]
      }
    },
    "facilities": [
      { "id": "65doc...", "name": "Swimming Pool", "icon": "pool", "type": "Sport" }
    ]
  }
}
```

### 1.2 Education Systems (Hierarchy)
**Endpoint**: `GET /api/public/education-systems`
**Use Case**: Get the full tree of Systems -> Tracks -> Stages -> Grades for structure selection.

#### Response Example
```json
{
  "success": true,
  "systems": [
    {
      "id": "67b0d...",
      "name": "American Diploma",
      "type": "International",
      "tracks": [
        {
          "id": "67b0e...",
          "name": "American High School"
        }
      ],
      "stages": [
        {
          "id": "67b0f...",
          "name": "High School",
          "grades": [
            { "id": "67b10...", "name": "Grade 10" },
            { "id": "67b11...", "name": "Grade 11" }
          ]
        }
      ]
    }
  ]
}
```

---

## 2. Parent Admission Flow
The admission process allows parents to select multiple schools. The first school incurs a flat registration fee, while subsequent selections in the same transaction are free (drafts).

### 2.1 Submit Application
**Endpoint**: `POST /api/admission/apply`
**Authentication**: Required (Parent Role)

#### Request Body
```json
{
  "childId": "65a123...", // MongoDB ObjectId of the student
  "selectedSchools": [
    {
      "_id": "67b55...", // ID of the first school (Primary Application)
      "name": "Future International School",
      "admissionFee": { 
        "amount": 1600,
        "currency": "EGP"
      }
    },
    {
      "_id": "67b66...", // ID of second school (Draft Application)
      "name": "Cairo Language School",
      "admissionFee": { "amount": 1200 } // Ignored for fee calculation, but saved
    }
  ]
}
```

#### Processing Logic (Backend)
1.  **Validation**: Checks if student already has an active application.
2.  **Fee Calculation**: Identifies the *highest* admission fee from the list (Applied only once).
3.  **Wallet Check**: Verifies parent wallet balance >= Calculated Fee.
4.  **Debit**: Deducts amount from parent wallet.
5.  **Credit (Hold)**: Logs a "Hold Income" transaction for the School Owner.
6.  **Creation**:
    *   School 1 -> Status: `pending` (Paid)
    *   School 2+ -> Status: `draft` (Unpaid/Reservation)
7.  **Notification**: Sends email to Parent (Receipt) and School Owner (New Lead).

#### Response
```json
{
  "message": "✅ تم إنشاء الطلبات بنجاح",
  "applications": [
    {
      "_id": "67c11...",
      "status": "pending",
      "priority": 0,
      "school": "67b55...",
      "payment": { "amount": 1600, "isPaid": true }
    },
    {
      "_id": "67c12...",
      "status": "draft",
      "priority": 1,
      "school": "67b66...",
      "payment": { "amount": 0, "isPaid": true } // Paid as part of the package
    }
  ]
}
```

### 2.2 Get My Applications
**Endpoint**: `GET /api/application`
**Authentication**: Required (Parent Role)

#### Response
Returns a list of all applications submitted by the logged-in parent.
```json
[
  {
    "_id": "67c11...",
    "status": "pending",
    "child": { "name": "Ahmed Ali", "grade": "Grade 4" },
    "school": { "name": "Future International School", "logoUrl": "..." },
    "createdAt": "2026-02-16T10:00:00Z"
  }
]
```

---

## 3. Sales School Onboarding Flow
This API is a "mega-endpoint" used by the Sales team to onboard a new school completely in one go. It handles user creation, school profile, and academic structure generation.

### 3.1 Create School (Onboarding)
**Endpoint**: `POST /api/sales/onboarding`
**Authentication**: Required (Admin/Sales Role)

#### Request Body
```json
{
  "schoolData": {
    "name": "Elite International School",
    "nameEn": "Elite International School",
    "type": "Private", // Should match IDs from GET /api/public/lookups
    "educationSystemId": "67b0d...", // ID from GET /api/public/education-systems
    "financials": {
      "registrationFees": 1600,
      "registrationDiscount": 0
    },
    "location": {
      "governorate": "Cairo", // Matches egyptData
      "educationalAdministration": "New Cairo",
      "detailedAddress": "90th St...",
      "coordinates": { "lat": 30.0, "lng": 31.2 }
    },
    "selectedStructure": {
        // Complex object determining which stages/grades are active
        // This mirrors the structure from GET /api/public/education-systems
        "stages": { "67b0f...": { "active": true } },
        "classes": { "67b10...": { "active": true, "fees": 25000 } }
    },
    "gender": "Mixed", // From Lookups
    "religionType": "None", // From Lookups
    "facilities": [
       { "facilityId": "65doc...", "value": "Yes" }
    ]
  },
  "ownerData": {
    "name": "Dr. Owner",
    "email": "owner@elite.edu.eg",
    "phone": "01000000001",
    "password": "securePass123"
  },
  "moderatorData": {
    "name": "Mr. Manager",
    "email": "manager@elite.edu.eg",
    "phone": "01000000002",
    "password": "managerPass123"
  },
  "configData": {
    "logo": "data:image/png;base64,...", // Base64 string (Uploaded automatically)
    "buildings": ["data:image/jpeg;base64,..."], // Array of Base64 strings
    "approved": true,
    "showInSearch": true,
    "theme": { "primaryColor": "#0f172a", "secondaryColor": "#334155" }
  },
  "customUsers": [] // Optional extra staff
}
```

#### Processing Logic (Backend)
1.  **Media Upload**: Recursively uploads Base64 images to ImageKit and replaces them with URLs.
2.  **User Provisioning**:
    *   Checks if Owner/Moderator exists.
    *   Creates them if not.
    *   Upgrades roles (`school_owner`, `moderator`).
3.  **School Creation**: Creates the `School` document with all configuration.
4.  **Academic Structure Generation**:
    *   Reads the `selectedStructure` map.
    *   **Generates Real Documents**: Creates `Stage`, `Grade`, `Classroom`, and `Subject` documents in MongoDB linked to this new school.
    *   This removes the need for manual setup later.
5.  **Facilities**: Links selected facilities.

#### Response
```json
{
  "message": "School created successfully",
  "schoolId": "67d99..."
}
```

---

## 4. Admin Management APIs

### 4.1 List Schools
**Endpoint**: `GET /api/admin/schools?q=SearchTerm`
**Authentication**: Required (Admin)
**Description**: Returns a paginated/filtered list of all schools in the system.

### 4.2 Create School (Direct)
**Endpoint**: `POST /api/admin/schools`
**Authentication**: Required (Admin)
**Description**: Quick creation of a school without the full onboarding wizard (Owner/Structure must be linked manually later using `PUT` endpoints).

---

## Developer Guide: Using Dropdowns
For any frontend dropdown in the onboarding or admission flow, developers **MUST** use data from `GET /api/public/lookups` instead of hardcoding values.

**Example Usage (React/Next.js):**
```javascript
// Fetch drop-down options
const { data } = await fetch('/api/public/lookups').then(res => res.json());

// Render School Type Select
<select>
  {data.schoolTypes.map(type => (
    <option value={type.id}>{type.label}</option>
  ))}
</select>

// Render Governorates
<select>
  {data.locations.governorates.map(gov => (
    <option value={gov.nameAr}>{gov.nameAr}</option>
  ))}
</select>
```
