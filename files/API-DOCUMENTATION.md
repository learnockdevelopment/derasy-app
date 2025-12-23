# Derasy Platform API Documentation

## Table of Contents
1. [Authentication APIs](#authentication-apis)
2. [User Management APIs](#user-management-apis)
3. [School Management APIs](#school-management-apis)
4. [Student Management APIs](#student-management-apis)
5. [Children Management APIs](#children-management-apis)
6. [Admission Flow APIs](#admission-flow-apis)
7. [Attendance APIs](#attendance-apis)
7. [Card Management APIs](#card-management-apis)
8. [Admin APIs](#admin-apis)
9. [Notification APIs](#notification-apis)
10. [Chatbot APIs](#chatbot-apis)
11. [Store Management APIs](#store-management-apis)
12. [Bus Management APIs](#bus-management-apis)
13. [Other APIs](#other-apis)

---

## How to Use
- All endpoints are under `/api/`
- Most endpoints require authentication via Bearer token in the `Authorization` header
- For detailed request/response examples, see each section below

---

## Authentication APIs
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST   | /api/login | User login |
| POST   | /api/logout | User logout |
| POST   | /api/register | User registration |
| POST   | /api/auth/sign-in | Auth sign-in (NextAuth) |
| POST   | /api/login/token | Token-based login |

## User Management APIs
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET    | /api/users/me | Get current user profile |
| GET    | /api/users/search | Search users |
| POST   | /api/create-user | Create a new user |
| GET    | /api/user/seed | Seed user data |

## School Management APIs
### Employees
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET    | /api/schools/my/[id]/hr/employees | List all employees for a school | Yes |
| GET    | /api/schools/my/[id]/hr/employees?employeeId= | Get single employee by ID | Yes |
| POST   | /api/schools/my/[id]/hr/employees | Add new employee | Yes |
| PUT    | /api/schools/my/[id]/hr/employees | Update employee (by employeeId in body) | Yes |
| DELETE | /api/schools/my/[id]/hr/employees?employeeId= | Delete employee by ID | Yes |

#### Example: Get all employees
```http
GET /api/schools/my/1234567890abcdef12345678/hr/employees
Authorization: Bearer <token>
```

#### Example: Add employee
```http
POST /api/schools/my/1234567890abcdef12345678/hr/employees
Content-Type: application/json
Authorization: Bearer <token>
{
  "user": "userId",
  "emptype": "typeId",
  ...
}
```

### Buses - Routes
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET    | /api/schools/my/[id]/buses/[busId]/routes | List all routes for a bus | Yes |
| POST   | /api/schools/my/[id]/buses/[busId]/routes | Add new route | Yes |
| PUT    | /api/schools/my/[id]/buses/[busId]/routes | Update route (by routeId in body) | Yes |
| DELETE | /api/schools/my/[id]/buses/[busId]/routes?routeId= | Delete route by ID | Yes |

### Buses - Students
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET    | /api/schools/my/[id]/buses/[busId]/students | List all students assigned to a bus | Yes |
| POST   | /api/schools/my/[id]/buses/[busId]/students | Assign student to bus | Yes |
| PUT    | /api/schools/my/[id]/buses/[busId]/students | Update student assignment (by assignmentId in body) | Yes |
| DELETE | /api/schools/my/[id]/buses/[busId]/students?assignmentId= | Remove student from bus | Yes |

## App Settings APIs
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET    | /api/app-settings | Get all app settings | Yes |
| POST   | /api/app-settings | Create/update settings | Admin |
| PUT    | /api/app-settings | Update specific section | Admin |

## Secure Example API
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET    | /api/secure-example | Secure GET (API key required) | API Key |
| POST   | /api/secure-example | Secure POST (API key required) | API Key |
| PUT    | /api/secure-example | Secure PUT (admin API key) | API Key |
| DELETE | /api/secure-example | Secure DELETE (admin API key) | API Key |

#### Example: Secure GET
```http
GET /api/secure-example?page=1&limit=10
x-api-key: <your-api-key>
```

---

### Store Orders API

| Method | Path | Description | Auth | Notes |
|--------|------|-------------|------|-------|
| GET    | /api/store/orders | List orders (user or admin) | Yes | Admin sees all, user sees own |
| POST   | /api/store/orders | Create new order from cart | Yes | Deducts from wallet |
| GET    | /api/store/orders/[id] | Get order by ID | Yes | User or admin |
| PUT    | /api/store/orders/[id] | Update order status | Yes (admin/moderator/school_owner) | |

### Store Cart API

| Method | Path | Description | Auth | Notes |
|--------|------|-------------|------|-------|
| GET    | /api/store/cart | Get user cart | Yes | Uses cookies |
| POST   | /api/store/cart | Add item to cart | Yes | |
| DELETE | /api/store/cart | Remove item from cart | Yes | |
| PUT    | /api/store/cart | Update cart item quantity | Yes | |

### Store Categories API

| Method | Path | Description | Auth | Notes |
|--------|------|-------------|------|-------|
| GET    | /api/store/categories | List categories | No | Supports parent filter |
| POST   | /api/store/categories | Create category | Yes (admin/moderator/school_owner) | |
| GET    | /api/store/categories/[id] | Get category by ID | No | |
| PUT    | /api/store/categories/[id] | Update category | Yes (admin/moderator/school_owner) | |
| DELETE | /api/store/categories/[id] | Delete category | Yes (admin/moderator/school_owner) | Soft delete, only if no products/subcategories |

---

## Children Management APIs

### Add Child (Parent)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST   | /api/children | Add child(ren) for authenticated parent | Yes (parent) |

**Request Headers:**
```http
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
- Can be a single object or an array of objects
- **Required fields:** `arabicFullName` OR `fullName`, `gender`, `birthDate`
- **Optional fields:** `nationalId`, `nationality`, `religion`, `birthPlace`, `desiredGrade`, `currentSchool`, `currentGrade`, `zone`, `specialNeeds`, `languagePreference`, `healthStatus`, `schoolId`, `birthCertificate`

**Birth Certificate Format:**
The `birthCertificate` field can be included to automatically extract data and save the certificate as a document:
```json
{
  "birthCertificate": {
    "data": "base64_encoded_image_string",
    "mimeType": "image/jpeg"
  }
}
```

**Example Request:**
```json
{
  "arabicFullName": "أحمد محمد",
  "fullName": "Ahmed Mohamed",
  "gender": "male",
  "birthDate": "2015-05-15",
  "nationalId": "12345678901234",
  "nationality": "Egyptian",
  "religion": "Muslim",
  "birthPlace": "Cairo",
  "desiredGrade": "Grade 1",
  "currentSchool": "Previous School Name",
  "currentGrade": "KG2",
  "zone": "القاهرة",
  "specialNeeds": {
    "hasNeeds": false,
    "description": ""
  },
  "languagePreference": {
    "primaryLanguage": "Arabic",
    "secondaryLanguage": "English"
  },
  "healthStatus": {
    "vaccinated": true,
    "notes": ""
  },
  "schoolId": "school_id_if_transferring",
  "birthCertificate": {
    "data": "data:image/jpeg;base64,/9j/4AAQ...",
    "mimeType": "image/jpeg"
  }
}
```

**Response Cases:**
- **201 Created:** Child(ren) added successfully
```json
{
  "message": "1 child(ren) added successfully",
  "children": [
    {
      "_id": "child_id",
      "arabicFullName": "أحمد محمد",
      "fullName": "Ahmed Mohamed",
      "gender": "male",
      "birthDate": "2015-05-15T00:00:00.000Z",
      "parent": {
        "user": "parent_user_id",
        "type": "father"
      },
      "studentStatus": {
        "status": "newcomer",
        "statusDate": "2024-01-15T10:00:00.000Z"
      },
      "documents": [
        {
          "url": "data:image/jpeg;base64,...",
          "label": "birth_certificate",
          "source": "uploaded",
          "uploadedAt": "2024-01-15T10:00:00.000Z"
        }
      ],
      "createdAt": "2024-01-15T10:00:00.000Z",
      "updatedAt": "2024-01-15T10:00:00.000Z"
    }
  ]
}
```

- **400 Bad Request:** Missing required fields
```json
{
  "message": "Missing required fields in one or more children",
  "error": "MISSING_REQUIRED_FIELDS",
  "details": {
    "arabicFullName": false,
    "gender": true,
    "birthDate": false
  }
}
```

- **403 Forbidden:** Unauthorized
```json
{
  "message": "Unauthorized"
}
```

- **500 Internal Server Error:**
```json
{
  "message": "Internal Server Error",
  "error": "Error message details"
}
```

**Notes:**
- Automatically sends confirmation email to parent after successful creation
- Parent ID is automatically set from authenticated user: `{ user: ObjectId, type: "father" }`
- Supports batch creation (array of children)
- Birth certificate is automatically saved to `documents` array with label `birth_certificate`
- `studentStatus.status` defaults to `"newcomer"` if not provided
- `desiredGrade` is optional (not required)

---

### Get Children by School (School Owner)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET    | /api/children?schoolId= | Get children list for a school | Yes (school_owner) |

**Request Headers:**
```http
Authorization: Bearer <token>
```

**Query Parameters:**
- `schoolId` (required): School ID

**Example Request:**
```http
GET /api/children?schoolId=1234567890abcdef12345678
Authorization: Bearer <token>
```

**Response Cases:**
- **200 Success:**
```json
{
  "children": [
    {
      "_id": "child_id",
      "fullName": "Ahmed Mohamed"
    }
  ]
}
```

- **400 Bad Request:** School ID missing
```json
{
  "message": "School ID is required"
}
```

- **403 Forbidden:** Unauthorized
```json
{
  "message": "Unauthorized"
}
```

---

### Get All Related Children (Parent)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET    | /api/children/get-related | Get all children related to authenticated parent | Yes (parent) |

**Request Headers:**
```http
Authorization: Bearer <token>
```

**Example Request:**
```http
GET /api/children/get-related
Authorization: Bearer <token>
```

**Response Cases:**
- **200 Success:**
```json
{
  "children": [
    {
      "_id": "child_id",
      "arabicFullName": "أحمد محمد",
      "fullName": "Ahmed Mohamed",
      "gender": "male",
      "birthDate": "2015-05-15T00:00:00.000Z",
      "nationalId": "12345678901234",
      "nationality": "Egyptian",
      "religion": "Muslim",
      "currentSchool": "Previous School",
      "desiredGrade": "Grade 1",
      "parent": {
        "_id": "parent_id",
        "fullName": "Parent Name",
        "email": "parent@example.com",
        "phone": "01234567890"
      },
      "parent": {
        "user": {
          "_id": "parent_id",
          "fullName": "Parent Name",
          "email": "parent@example.com",
          "phone": "01234567890"
        },
        "type": "father"
      },
      "schoolId": {
        "_id": "school_id",
        "name": "School Name",
        "nameAr": "اسم المدرسة",
        "logo": { "url": "logo_url" },
        "branches": []
      },
      "stage": {
        "_id": "stage_id",
        "name": "Primary",
        "nameAr": "ابتدائي"
      },
      "grade": {
        "_id": "grade_id",
        "name": "Grade 1",
        "nameAr": "الصف الأول"
      },
      "section": {
        "_id": "section_id",
        "name": "Section A",
        "nameAr": "قسم أ"
      },
      "class": {
        "_id": "class_id",
        "name": "Class 1A",
        "nameAr": "فصل 1أ"
      },
      "guardians": [
        {
          "user": {
            "_id": "guardian_id",
            "fullName": "Guardian Name",
            "email": "guardian@example.com",
            "phone": "01234567891"
          },
          "relation": "father",
          "isParent": true
        }
      ],
      "documents": [
        {
          "url": "document_url",
          "label": "birth_certificate",
          "source": "uploaded",
          "uploadedAt": "2024-01-15T10:00:00.000Z"
        }
      ],
      "createdAt": "2024-01-15T10:00:00.000Z",
      "updatedAt": "2024-01-15T10:00:00.000Z"
    }
  ]
}
```

- **403 Forbidden:** Unauthorized
```json
{
  "message": "Unauthorized"
}
```

- **500 Internal Server Error:**
```json
{
  "message": "Internal server error",
  "error": "Error message details"
}
```

**Notes:**
- Returns children where the user is either the parent or a guardian
- Handles both legacy parent structure (ObjectId) and new structure ({ user: ObjectId, type: String })
- All related data (school, stage, grade, section, class, guardians) are populated
- Results are sorted by creation date (newest first)

---

### Get Single Child by ID (Parent)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET    | /api/children/get-related/[id] | Get single child by ID | Yes (parent) |

**Request Headers:**
```http
Authorization: Bearer <token>
```

**Example Request:**
```http
GET /api/children/get-related/694a93b4707b36f746049ffa
Authorization: Bearer <token>
```

**Response Cases:**
- **200 Success:**
```json
{
  "child": {
    "_id": "child_id",
    "arabicFullName": "أحمد محمد",
    "fullName": "Ahmed Mohamed",
    "gender": "male",
    "birthDate": "2015-05-15T00:00:00.000Z",
    "schoolId": {
      "_id": "school_id",
      "name": "School Name",
      "nameAr": "اسم المدرسة",
      "logo": { "url": "logo_url" },
      "branches": [],
      "type": "Private",
      "location": {
        "governorate": "Cairo",
        "city": "Cairo",
        "district": "Nasr City"
      },
      "contactEmail": "school@example.com",
      "contactPhone": "01234567890",
      "languages": ["Arabic", "English"]
    },
    "documents": [],
    "profileImage": { "url": "profile_url" },
    "createdAt": "2024-01-15T10:00:00.000Z"
  }
}
```

- **403 Forbidden:** Unauthorized
```json
{
  "message": "Unauthorized"
}
```

- **404 Not Found:**
```json
{
  "message": "Child not found"
}
```

- **500 Internal Server Error:**
```json
{
  "message": "Internal server error",
  "error": "Error message details"
}
```

**Notes:**
- Verifies parent ownership before returning child data
- Populates all related school information including branches, location, and contact details

---

### Update Child (Parent)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| PUT    | /api/children/get-related/[id] | Update child information | Yes (parent) |

**Request Headers:**
```http
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
- All fields are optional
- Only include fields you want to update
- **Important:** Do not send empty strings for enum fields (`religion`, `languagePreference.primaryLanguage`)

**Example Request:**
```json
{
  "currentSchool": "New School Name",
  "currentGrade": "KG2",
  "desiredGrade": "Grade 1",
  "religion": "Muslim",
  "zone": "القاهرة",
  "birthPlace": "Cairo",
  "specialNeeds": {
    "hasNeeds": false,
    "description": ""
  },
  "languagePreference": {
    "primaryLanguage": "Arabic",
    "secondaryLanguage": "English"
  },
  "healthStatus": {
    "vaccinated": true,
    "notes": "All vaccinations up to date"
  }
}
```

**Response Cases:**
- **200 Success:**
```json
{
  "message": "Child updated successfully",
  "child": {
    "_id": "child_id",
    "currentSchool": "New School Name",
    "desiredGrade": "Grade 1",
    "updatedAt": "2024-01-15T11:00:00.000Z"
  }
}
```

- **400 Bad Request:** Validation error
```json
{
  "message": "Child validation failed: religion: `` is not a valid enum value"
}
```

- **403 Forbidden:** Unauthorized
```json
{
  "message": "Unauthorized"
}
```

- **404 Not Found:**
```json
{
  "message": "Child not found or unauthorized"
}
```

- **500 Internal Server Error:**
```json
{
  "message": "Internal server error",
  "error": "Error message details"
}
```

**Notes:**
- Only updates fields that are provided in the request body
- Empty strings for enum fields are ignored (not updated)
- Verifies parent ownership before updating

---

### Upload Child Document/Profile Image (Parent)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| PUT    | /api/children/get-related/[id]/upload | Upload document or profile image for child | Yes (parent) |

**Request Headers:**
```http
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Form Data:**
- `file` (required): Image or PDF file
- `label` (optional): Document label/name
- `type` (required): Either `"document"` or `"profile"`

**Example Request:**
```http
PUT /api/children/get-related/694a93b4707b36f746049ffa/upload
Authorization: Bearer <token>
Content-Type: multipart/form-data

file: [binary file data]
label: "Birth Certificate"
type: "document"
```

**Response Cases:**
- **200 Success:**
```json
{
  "message": "Uploaded successfully",
  "child": {
    "_id": "child_id",
    "profileImage": {
      "url": "https://imagekit.io/...",
      "publicId": "file_id"
    },
    "documents": [
      {
        "url": "https://imagekit.io/...",
        "publicId": "file_id",
        "label": "Birth Certificate"
      }
    ]
  }
}
```

- **400 Bad Request:** Invalid file
```json
{
  "message": "Invalid file"
}
```

- **401 Unauthorized:**
```json
{
  "message": "Unauthorized"
}
```

- **404 Not Found:**
```json
{
  "message": "Child not found"
}
```

- **500 Internal Server Error:**
```json
{
  "message": "Internal error",
  "error": "Error message details"
}
```

**Notes:**
- Files are uploaded to ImageKit
- Profile images are stored in `profileImage` field
- Documents are added to `documents` array
- Verifies parent ownership before uploading

---

### Extract Birth Certificate Data (Parent)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST   | /api/children/extract-birth-certificate | Extract data from Egyptian birth certificate using AI | Yes (parent) |

**Request Headers:**
```http
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Form Data:**
- `birthCertificate` (required): Image file (JPEG, PNG, WebP)

**Example Request:**
```http
POST /api/children/extract-birth-certificate
Authorization: Bearer <token>
Content-Type: multipart/form-data

birthCertificate: [binary image file]
```

**Response Cases:**
- **200 Success:**
```json
{
  "success": true,
  "extractedData": {
    "fullName": "Ahmed Mohamed Ali",
    "arabicFullName": "أحمد محمد علي",
    "firstName": "Ahmed",
    "lastName": "Mohamed Ali",
    "arabicFirstName": "أحمد",
    "arabicLastName": "محمد علي",
    "birthDate": "2015-05-15",
    "gender": "male",
    "nationalId": "12345678901234",
    "nationality": "Egyptian",
    "birthPlace": "Cairo",
    "religion": "Muslim",
    "birthCertificateImage": {
      "data": "base64_encoded_image",
      "mimeType": "image/jpeg",
      "size": 123456,
      "name": "birth_certificate.jpg"
    }
  }
}
```

- **400 Bad Request:** Missing file
```json
{
  "message": "Birth certificate file is required"
}
```

- **403 Forbidden:** Unauthorized
```json
{
  "message": "Unauthorized"
}
```

- **409 Conflict:** National ID already exists
```json
{
  "message": "Child with this national ID already exists",
  "existingChildId": "child_id"
}
```
or
```json
{
  "message": "National ID already registered in system",
  "existingUserId": "user_id"
}
```

- **503 Service Unavailable:** AI service unavailable
```json
{
  "message": "AI_EXTRACTION_UNAVAILABLE",
  "error": "API rate limit exceeded. Please wait a moment and try again.",
  "errorCode": "RATE_LIMIT_EXCEEDED",
  "suggestion": "MANUAL_ENTRY_AVAILABLE",
  "canContinue": true
}
```

- **500 Internal Server Error:**
```json
{
  "message": "Internal server error",
  "error": "Error message details"
}
```

**Notes:**
- Uses Google Gemini Vision API for data extraction
- Validates that national ID is not already in use (as child or user)
- Returns base64 encoded image for saving to child documents
- If AI service fails, returns `canContinue: true` to allow manual entry
- Extracts birth date and gender from 14-digit National ID if available

---

## Admission Flow APIs
 
### Apply to Schools (Parent)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST   | /api/admission/apply | Apply to multiple schools with payment processing | Yes (parent) |

**Request Headers:**
```http
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "childId": "child_id",
  "selectedSchools": [
    {
      "_id": "school_id_1",
      "name": "School Name 1",
      "admissionFee": {
        "amount": 500
      }
    },
    {
      "_id": "school_id_2",
      "name": "School Name 2",
      "admissionFee": {
        "amount": 300
      }
    }
  ]
}
```

**Response Cases:**
- **200 Success:** Applications created successfully
```json
{
  "message": "✅ تم إنشاء الطلبات بنجاح",
  "applications": [
    {
      "_id": "application_id",
      "parent": "parent_id",
      "child": "child_id",
      "school": "school_id",
      "status": "pending",
      "payment": {
        "isPaid": true,
        "amount": 500
      },
      "preferredInterviewSlots": [
        {
          "date": "2024-01-15T00:00:00.000Z",
          "timeRange": {
            "from": "10:00",
            "to": "12:00"
          }
        }
      ],
      "createdAt": "2024-01-15T10:00:00.000Z"
    }
  ]
}
```

- **400 Bad Request:** Insufficient wallet balance or incomplete data
```json
{
  "message": "رصيدك غير كافٍ. تحتاج إلى 500 جنيه على الأقل."
}
```
or
```json
{
  "message": "بيانات غير كاملة"
}
```

- **404 Not Found:** School or user not found
```json
{
  "message": "لم يتم العثور على المدرسة المحددة."
}
```
or
```json
{
  "message": "لم يتم العثور على المستخدم."
}
```

- **401 Unauthorized:** User is not a parent
```json
{
  "message": "غير مصرح"
}
```

- **409 Conflict:** Duplicate application exists
```json
{
  "message": "⚠️ لديك بالفعل طلب لهذه المدرسة."
}
```

- **500 Internal Server Error:**
```json
{
  "message": "حدث خطأ داخلي",
  "error": "Error message details"
}
```

**Notes:**
- Schools are automatically sorted by highest admission fee
- Payment is deducted from parent's wallet for the top school (highest fee)
- **Wallet is automatically initialized** if it doesn't exist (balance: 0, currency: EGP)
- First school gets status "pending" (paid), others get "draft" (unpaid)
- Full school data is fetched from database to ensure accurate ownership information
- Creates transaction records for:
    - Parent: "withdraw" transaction (always created)
    - School owner: "hold_income" transaction (only if owner exists)
- Sends confirmation emails to:
    - Parent: Payment confirmation and application summary (always sent)
    - School owner: New application notification (only if owner exists)
- Prevents duplicate applications to the same school (unless status is "accepted" or "rejected")
- **Application submission will succeed even if school owner is not found** (non-blocking)

---

### Create Application (Parent - Simple)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST   | /api/application | Create a simple application | Yes (parent) |

**Request Headers:**
```http
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "child": "child_id",
  "school": "school_id",
  "status": "pending",
  "notes": "Optional notes"
}
```

**Response Cases:**
- **200 Success:** Application created
```json
{
  "_id": "application_id",
  "parent": "parent_id",
  "child": "child_id",
  "school": "school_id",
  "status": "pending",
  "createdAt": "2024-01-15T10:00:00.000Z"
}
```

- **401 Unauthorized:** User is not a parent

---

### Get User Applications (Parent)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET    | /api/application | Get all applications for authenticated parent | Yes (parent) |

**Request Headers:**
```http
Authorization: Bearer <token>
```

**Example Request:**
```http
GET /api/application
Authorization: Bearer <token>
```

**Response Cases:**
- **200 Success:**
```json
[
  {
    "_id": "application_id",
    "parent": "parent_id",
    "child": {
      "_id": "child_id",
      "fullName": "Ahmed Mohamed",
      "birthDate": "2015-05-15T00:00:00.000Z"
    },
    "school": {
      "_id": "school_id",
      "name": "School Name",
      "address": "School Address"
    },
    "status": "pending",
    "createdAt": "2024-01-15T10:00:00.000Z"
  }
]
```

- **401 Unauthorized:** User not authenticated

---

### Get Single Application (Parent)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET    | /api/application/[id] | Get single application by ID | Yes (parent) |

**Request Headers:**
```http
Authorization: Bearer <token>
```

**Example Request:**
```http
GET /api/application/1234567890abcdef12345678
Authorization: Bearer <token>
```

**Response Cases:**
- **200 Success:**
```json
{
  "_id": "application_id",
  "parent": "parent_id",
  "child": {
    "_id": "child_id",
    "fullName": "Ahmed Mohamed",
    "gender": "male",
    "birthDate": "2015-05-15T00:00:00.000Z"
  },
  "school": {
    "_id": "school_id",
    "name": "School Name",
    "nameAr": "اسم المدرسة",
    "address": "School Address"
  },
  "status": "pending",
  "payment": {
    "isPaid": true,
    "amount": 500
  },
  "preferredInterviewSlots": [],
  "notes": "Application notes",
  "createdAt": "2024-01-15T10:00:00.000Z",
  "updatedAt": "2024-01-15T10:00:00.000Z"
}
```

- **404 Not Found:** Application not found
```json
{
  "message": "لم يتم العثور على الطلب"
}
```

- **401 Unauthorized:** User is not a parent or doesn't own the application

- **500 Internal Server Error:**
```json
{
  "message": "خطأ في تحميل الطلب"
}
```

---

### Get School Applications (School Owner)
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET    | /api/schools/my/[id]/admission-forms | Get all applications for a school | Yes (school_owner/moderator) |

**Request Headers:**
```http
Authorization: Bearer <token>
```

**Example Request:**
```http
GET /api/schools/my/1234567890abcdef12345678/admission-forms
Authorization: Bearer <token>
```

**Response Cases:**
- **200 Success:**
```json
{
  "applications": [
    {
      "_id": "application_id",
      "parent": {
        "_id": "parent_id",
        "name": "Parent Name",
        "email": "parent@example.com"
      },
      "child": {
        "_id": "child_id",
        "fullName": "Ahmed Mohamed"
      },
      "school": {
        "_id": "school_id",
        "name": "School Name"
      },
      "status": "pending",
      "submittedAt": "2024-01-15T10:00:00.000Z"
    }
  ],
  "school": {
    "_id": "school_id",
    "name": "School Name"
  },
  "totalApplications": 25,
  "byStatus": {
    "pending": 10,
    "under_review": 5,
    "accepted": 7,
    "rejected": 3
  }
}
```

- **400 Bad Request:** Invalid school ID
```json
{
  "message": "معرف المدرسة غير صالح"
}
```

- **403 Forbidden:** Unauthorized
```json
{
  "message": "غير مصرح"
}
```

- **500 Internal Server Error:**
```json
{
  "message": "خطأ في الخادم",
  "error": "Error message details"
}
```

**Notes:**
- Returns all applications for the specified school
- Includes statistics by status (pending, under_review, accepted, rejected)
- Results are sorted by submission date (newest first)
- Applications are populated with parent, child, and school data

---

## [More endpoints and details can be added as needed.]

_Last updated: December 21, 2025_