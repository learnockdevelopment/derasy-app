# Derasy Platform API Documentation

> **📖 Documentation Files:**
> - **[API-README.md](./API-README.md)** - Quick start guide and common use cases
> - **[API-WORKFLOWS.md](./API-WORKFLOWS.md)** - Step-by-step workflows and code examples
> - **This file** - Complete API reference

---

## 📚 Table of Contents
1. [Quick Start Guide](#quick-start-guide)
2. [Authentication](#authentication)
3. [Children Management APIs](#children-management-apis)
  - [Add Child with Birth Certificate Extraction](#add-child-with-birth-certificate-extraction)
  - [Two-Step Document Upload Flow](#two-step-document-upload-flow)
  - [OTP Verification Flow for Existing Children](#otp-verification-flow-for-existing-children)
  - [Non-Egyptian Child Requests Flow](#non-egyptian-child-requests-flow)
  - [Admin: Non-Egyptian Child Requests Management](#admin-non-egyptian-child-requests-management)
  - [Get Children](#get-children)
  - [Update Child](#update-child)
  - [Upload Documents](#upload-documents)
4. [Admission Flow APIs](#admission-flow-apis)
5. [Common Workflows](#common-workflows)
6. [Error Handling](#error-handling)

---

## 🚀 Quick Start Guide

### Base URL
All API endpoints are under `/api/`

### Authentication
Most endpoints require authentication via Bearer token:
```http
Authorization: Bearer <your_token>
```

### Content Types
- **JSON APIs:** `Content-Type: application/json`
- **File Upload APIs:** `Content-Type: multipart/form-data`

---

## 🔐 Authentication

### Login
```http
POST /api/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "user_id",
    "role": "parent",
    "email": "user@example.com"
  }
}
```

---

## 👶 Children Management APIs

### Add Child with Birth Certificate Extraction

This is the **recommended flow** for adding a child with automatic data extraction from birth certificate.

#### Step 1: Extract Birth Certificate Data

**Endpoint:** `POST /api/children/extract-birth-certificate`

**Description:** Extracts data from Egyptian birth certificate, National ID, or Passport using Google Gemini AI. This endpoint also validates parent National ID if provided.

**Request:**
```http
POST /api/children/extract-birth-certificate
Authorization: Bearer <token>
Content-Type: multipart/form-data

Form Data:
- birthCertificate: [image file] (required)
```

**Response (200 Success):**
```json
{
  "success": true,
  "extractedData": {
    "arabicFullName": "نور الدین محمود سید عبد المبدى محمد علی",
    "fullName": "Nour El Din Mahmoud",
    "arabicFirstName": "نور الدین",
    "arabicLastName": "محمود سید عبد المبدى محمد علی",
    "firstName": "Nour",
    "lastName": "El Din Mahmoud",
    "nationalId": "31303170105673",
    "birthDate": "2013-06-03",
    "gender": "male",
    "nationality": "Egyptian",
    "birthPlace": "القاهره / مصر الجديده",
    "religion": "Muslim",
    "ageInComingOctober": {
      "years": 11,
      "months": 4,
      "totalMonths": 136,
      "targetDate": "2025-10-01",
      "formatted": "11 years and 4 months"
    },
    "fatherNationalId": "27206102102338",
    "motherNationalId": "27707280201101",
    "parentNationalIds": ["27206102102338", "27707280201101"],
    "birthCertificateImage": {
      "data": "base64_encoded_image",
      "mimeType": "image/jpeg",
      "size": 123456,
      "name": "birth_certificate.jpg"
    }
  },
  "extractedText": "جمهورية مصر العربية\nشهادة ميلاد...",
  "documentType": "birth_certificate"
}
```

**Response (409 Conflict - National ID exists):**
```json
{
  "message": "Child with this national ID already exists",
  "existingChildId": "child_id"
}
```

**Response (503 Service Unavailable - AI Error):**
```json
{
  "message": "OCR extraction failed. Please enter data manually.",
  "error": "Error details",
  "canContinue": true
}
```

**Notes:**
- ✅ Automatically detects document type (birth_certificate, national_id, passport)
- ✅ Extracts child's National ID from top of document
- ✅ Extracts both father's and mother's National IDs
- ✅ Converts Arabic-Indic numerals (٠١٢٣٤٥٦٧٨٩) to standard digits
- ✅ Handles Arabic written years (e.g., "عام الفان و ثلاثه عشر" = 2013)
- ✅ Calculates age in coming October automatically
- ✅ Combines child name + father name for full Arabic name
- ✅ Validates National ID uniqueness before extraction completes

---

#### Step 2: Add Child with Extracted Data

**Endpoint:** `POST /api/children`

**Description:** Creates a new child record. Can use extracted data from Step 1.

**Request:**
```http
POST /api/children
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "arabicFullName": "نور الدین محمود سید عبد المبدى محمد علی",
  "fullName": "Nour El Din Mahmoud",
  "gender": "male",
  "birthDate": "2013-06-03",
  "nationalId": "31303170105673",
  "nationality": "Egyptian",
  "birthPlace": "القاهره / مصر الجديده",
  "religion": "Muslim",
  "desiredGrade": "Grade 5",
  "currentSchool": "Previous School Name",
  "birthCertificate": {
    "data": "base64_encoded_image_from_step_1",
    "mimeType": "image/jpeg"
  }
}
```

**Required Fields:**
- `arabicFullName` OR `fullName` (at least one)
- `gender` (must be: "male", "female", or "other")
- `birthDate` (format: "YYYY-MM-DD")

**Optional Fields:**
- `nationalId` (14 digits)
- `nationality` (defaults to "Egyptian")
- `religion` ("Muslim", "Christian", or "Other")
- `birthPlace`
- `desiredGrade`
- `currentSchool`
- `schoolId` (if transferring from another school)
- `birthCertificate` (object with `data` and `mimeType`)

**Response (201 Created):**
```json
{
  "message": "1 child(ren) added successfully",
  "children": [
    {
      "_id": "child_id",
      "arabicFullName": "نور الدین محمود سید عبد المبدى محمد علی",
      "fullName": "Nour El Din Mahmoud",
      "gender": "male",
      "birthDate": "2013-06-03T00:00:00.000Z",
      "nationalId": "31303170105673",
      "ageInOctober": 136,
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
      "createdAt": "2024-01-15T10:00:00.000Z"
    }
  ]
}
```

**Response (400 Bad Request):**
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

**Response (409 Conflict - Child Already Exists):**
```json
{
  "message": "Child with this National ID already exists",
  "error": "CHILD_EXISTS",
  "child": {
    "id": "child_id",
    "fullName": "نور الدین محمود سید عبد المبدى محمد علی",
    "schoolName": "School Name",
    "nationalId": "31303170105673"
  },
  "guardians": [
    {
      "userId": "guardian_user_id",
      "name": "Guardian Name",
      "relation": "father",
      "phones": ["01234567890", "01123456789"]
    }
  ]
}
```

**Response (409 Conflict - Child Already in Parent's List):**
```json
{
  "message": "This child is already in your children list",
  "error": "CHILD_ALREADY_ADDED",
  "child": {
    "id": "child_id",
    "fullName": "Child Name"
  }
}
```

**Notes:**
- ✅ Automatically calculates `ageInOctober` (in months) from `birthDate`
- ✅ Saves birth certificate to `documents` array automatically
- ✅ Sends confirmation email to parent
- ✅ Supports batch creation (array of children)
- ✅ Checks for duplicate children in parent's list
- ✅ For new Egyptian children, `nationalId` is stored in `temporaryNationalId` field (not in primary `nationalId`) to prevent incorrect usage
- ✅ If child with same National ID exists, returns guardian phone numbers for OTP verification

---

### Two-Step Document Upload Flow

This flow is used when you need to **validate parent identity** before extracting child data.

#### Step 1: Upload Parent National ID Card

**Endpoint:** `POST /api/children/extract-birth-certificate`

**Description:** Upload parent's National ID card to extract parent's National ID number.

**Request:**
```http
POST /api/children/extract-birth-certificate
Authorization: Bearer <token>
Content-Type: multipart/form-data

Form Data:
- birthCertificate: [parent_national_id_image] (required)
```

**Response (200 Success):**
```json
{
  "success": true,
  "extractedData": {
    "nationalId": "27206102102338",
    "arabicFullName": "محمود سید عبد المبدى محمد علی",
    "birthDate": "1980-02-22",
    "gender": "male"
  },
  "documentType": "national_id"
}
```

**Frontend Action:** Store `extractedData.nationalId` as `parentNationalId` for validation in Step 2.

---

#### Step 2: Upload Child Birth Certificate

**Endpoint:** `POST /api/children/extract-birth-certificate`

**Description:** Upload child's birth certificate. The API will validate that the parent's National ID from Step 1 matches either the father's or mother's ID in the certificate.

**Request:**
```http
POST /api/children/extract-birth-certificate
Authorization: Bearer <token>
Content-Type: multipart/form-data

Form Data:
- birthCertificate: [child_birth_certificate_image] (required)
```

**Response (200 Success - Parent ID Matched):**
```json
{
  "success": true,
  "extractedData": {
    "arabicFullName": "نور الدین محمود سید عبد المبدى محمد علی",
    "nationalId": "31303170105673",
    "birthDate": "2013-06-03",
    "gender": "male",
    "fatherNationalId": "27206102102338",
    "motherNationalId": "27707280201101",
    "parentNationalIds": ["27206102102338", "27707280201101"],
    "birthCertificateImage": { ... }
  },
  "extractedText": "...",
  "documentType": "birth_certificate"
}
```

**Frontend Validation Logic:**
```javascript
// After receiving response from Step 2
const parentNationalId = "27206102102338"; // From Step 1
const fatherId = extractedData.fatherNationalId; // "27206102102338"
const motherId = extractedData.motherNationalId; // "27707280201101"

// Check if parent ID matches either father or mother
const isValid = parentNationalId === fatherId || parentNationalId === motherId;

if (isValid) {
  // ✅ Parent verified - proceed to add child
  // Use extractedData to fill form and call POST /api/children
} else {
  // ❌ Show error: Parent ID mismatch
  // Display both IDs for user to verify
}
```

**Response (if parent ID not found in certificate):**
The API will still return extracted data, but frontend should show a warning:
```javascript
// Warning message:
"⚠️ Parent National ID not found in birth certificate. 
You can continue manually, but please verify the data."
```

**Notes:**
- ✅ API extracts both father's and mother's National IDs
- ✅ Frontend should compare parent ID from Step 1 with both parent IDs from Step 2
- ✅ If match found → proceed to add child
- ✅ If no match → show error but allow manual entry

---

### OTP Verification Flow for Existing Children

When a parent tries to add a child with a National ID that already exists in the system, the API returns a `409 Conflict` response with guardian information. The parent must verify their identity via OTP before the child can be linked to their account.

#### Step 1: Send OTP to Guardian Phone

**Endpoint:** `POST /api/children/send-otp`

**Description:** Sends an OTP to a selected guardian's phone number for verification.

**Request:**
```http
POST /api/children/send-otp
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "childId": "child_id",
  "guardianUserId": "guardian_user_id",
  "phoneNumber": "01234567890"
}
```

**Required Fields:**
- `childId` - The ID of the existing child
- `guardianUserId` - The ID of the guardian whose phone will receive the OTP
- `phoneNumber` - The phone number to send OTP to (must belong to the guardian)

**Response (200 Success):**
```json
{
  "message": "OTP sent successfully",
  "phoneNumber": "01234567890"
}
```

**Response (400 Bad Request):**
```json
{
  "message": "Phone number does not belong to this guardian",
  "details": {
    "requestedPhone": "01234567890",
    "availablePhones": ["01234567890", "01123456789"]
  }
}
```

**Response (404 Not Found):**
```json
{
  "message": "Guardian not found"
}
```

**Notes:**
- ✅ Phone numbers are normalized (trimmed, spaces removed) before comparison
- ✅ OTP is valid for 10 minutes
- ✅ OTP is stored in the guardian's User model

---

#### Step 2: Verify OTP and Link Child

**Endpoint:** `POST /api/children/verify-otp`

**Description:** Verifies the OTP code and links the child to the parent's account.

**Request:**
```http
POST /api/children/verify-otp
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "childId": "child_id",
  "guardianUserId": "guardian_user_id",
  "otp": "123456"
}
```

**Required Fields:**
- `childId` - The ID of the existing child
- `guardianUserId` - The ID of the guardian who received the OTP
- `otp` - The 6-digit OTP code (test OTP: `123456` for development)

**Response (200 Success):**
```json
{
  "message": "OTP verified successfully. Child linked to your account.",
  "child": {
    "id": "child_id",
    "fullName": "Child Name"
  }
}
```

**Response (400 Bad Request):**
```json
{
  "message": "Invalid OTP code. Please check and try again."
}
```

**Response (400 Bad Request - Expired):**
```json
{
  "message": "OTP code has expired. Please request a new verification code."
}
```

**Response (400 Bad Request - No OTP):**
```json
{
  "message": "No OTP found. Please request a new OTP."
}
```

**Notes:**
- ✅ Test OTP `123456` bypasses validation for development/testing
- ✅ On successful verification, the parent is added to the child's `guardians` array
- ✅ The child's `parent` field is updated to reference the new parent
- ✅ OTP is cleared after successful verification
- ✅ Confirmation email is sent to the parent

---

### Non-Egyptian Child Requests Flow

For non-Egyptian children, parents must submit a request that requires admin approval before the child is added to the system.

#### Step 1: Submit Non-Egyptian Child Request

**Endpoint:** `POST /api/children/non-egyptian-request`

**Description:** Creates a request to add a non-Egyptian child. Requires parent and child passport uploads.

**Request:**
```http
POST /api/children/non-egyptian-request
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Form Data:**
- `parentPassport` - Parent's passport image/file (required)
- `childPassport` - Child's passport image/file (required)
- `fullName` - Child's full name in English (optional)
- `arabicFullName` - Child's full name in Arabic (required if fullName not provided)
- `firstName` - Child's first name (optional)
- `lastName` - Child's last name (optional)
- `birthDate` - Child's birth date in YYYY-MM-DD format (required)
- `gender` - Child's gender: "male", "female", or "other" (required)
- `nationality` - Child's nationality (defaults to "Non-Egyptian")
- `birthPlace` - Place of birth (optional)
- `religion` - Religion (optional)
- `desiredGrade` - Desired grade level (optional)
- `schoolId` - School ID if transferring (optional)
- `currentSchool` - Current school name (optional)

**Response (201 Created):**
```json
{
  "message": "Request submitted successfully",
  "request": {
    "id": "request_id",
    "status": "pending",
    "requestedAt": "2024-01-15T10:00:00.000Z"
  }
}
```

**Response (400 Bad Request):**
```json
{
  "message": "Parent passport is required"
}
```

**Response (400 Bad Request):**
```json
{
  "message": "Child name is required"
}
```

**Notes:**
- ✅ Passports are uploaded to ImageKit cloud storage
- ✅ Request status starts as "pending"
- ✅ Admin must approve or reject the request
- ✅ Parent can view request status in their children list

---

#### Step 2: Get Parent's Non-Egyptian Requests

**Endpoint:** `GET /api/children/non-egyptian-requests`

**Description:** Get all non-Egyptian child requests submitted by the authenticated parent.

**Request:**
```http
GET /api/children/non-egyptian-requests
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "requests": [
    {
      "_id": "request_id",
      "fullName": "John Doe",
      "arabicFullName": "جون دو",
      "birthDate": "2015-05-10T00:00:00.000Z",
      "gender": "male",
      "nationality": "Non-Egyptian",
      "status": "pending",
      "parentPassport": {
        "url": "https://imagekit.io/...",
        "uploadedAt": "2024-01-15T10:00:00.000Z"
      },
      "childPassport": {
        "url": "https://imagekit.io/...",
        "uploadedAt": "2024-01-15T10:00:00.000Z"
      },
      "requestedAt": "2024-01-15T10:00:00.000Z",
      "rejectionReason": null,
      "childId": null
    }
  ],
  "count": 1
}
```

**Request Statuses:**
- `pending` - Waiting for admin review
- `approved` - Request approved, child created
- `rejected` - Request rejected (includes `rejectionReason`)

---

### Admin: Non-Egyptian Child Requests Management

#### Get All Non-Egyptian Requests

**Endpoint:** `GET /api/admin/non-egyptian-requests`

**Description:** Get all non-Egyptian child requests (admin only). Can filter by status.

**Request:**
```http
GET /api/admin/non-egyptian-requests?status=pending
Authorization: Bearer <admin_token>
```

**Query Parameters:**
- `status` (optional) - Filter by status: "pending", "approved", "rejected", or omit for all

**Response (200 Success):**
```json
{
  "requests": [
    {
      "_id": "request_id",
      "requestedBy": {
        "_id": "parent_user_id",
        "name": "Parent Name",
        "email": "parent@example.com",
        "phone": "01234567890"
      },
      "fullName": "John Doe",
      "arabicFullName": "جون دو",
      "birthDate": "2015-05-10T00:00:00.000Z",
      "gender": "male",
      "nationality": "Non-Egyptian",
      "status": "pending",
      "parentPassport": {
        "url": "https://imagekit.io/...",
        "uploadedAt": "2024-01-15T10:00:00.000Z"
      },
      "childPassport": {
        "url": "https://imagekit.io/...",
        "uploadedAt": "2024-01-15T10:00:00.000Z"
      },
      "requestedAt": "2024-01-15T10:00:00.000Z",
      "schoolId": {
        "_id": "school_id",
        "name": "School Name",
        "nameAr": "اسم المدرسة"
      }
    }
  ],
  "count": 1
}
```

---

#### Approve Non-Egyptian Request

**Endpoint:** `POST /api/admin/non-egyptian-requests/[id]/approve`

**Description:** Approves a non-Egyptian child request and creates the child in the database (admin only).

**Request:**
```http
POST /api/admin/non-egyptian-requests/request_id/approve
Authorization: Bearer <admin_token>
```

**Response (200 Success):**
```json
{
  "message": "Request approved and child created successfully",
  "child": {
    "id": "child_id",
    "fullName": "John Doe"
  },
  "request": {
    "id": "request_id",
    "status": "approved"
  }
}
```

**Response (400 Bad Request):**
```json
{
  "message": "Request is already approved"
}
```

**Response (404 Not Found):**
```json
{
  "message": "Request not found"
}
```

**Notes:**
- ✅ Creates a new Child document with all request data
- ✅ Adds parent to child's guardians array
- ✅ Uploads passport documents to child's documents array (labeled as "other")
- ✅ Updates request status to "approved"
- ✅ Links child ID to request for tracking

---

#### Reject Non-Egyptian Request

**Endpoint:** `POST /api/admin/non-egyptian-requests/[id]/reject`

**Description:** Rejects a non-Egyptian child request with a reason (admin only).

**Request:**
```http
POST /api/admin/non-egyptian-requests/request_id/reject
Authorization: Bearer <admin_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "rejectionReason": "Missing required documents or incomplete information"
}
```

**Required Fields:**
- `rejectionReason` - Reason for rejection (required, cannot be empty)

**Response (200 Success):**
```json
{
  "message": "Request rejected successfully",
  "request": {
    "id": "request_id",
    "status": "rejected",
    "rejectionReason": "Missing required documents or incomplete information"
  }
}
```

**Response (400 Bad Request):**
```json
{
  "message": "Rejection reason is required"
}
```

**Response (400 Bad Request):**
```json
{
  "message": "Request is already rejected"
}
```

**Notes:**
- ✅ Updates request status to "rejected"
- ✅ Stores rejection reason for parent to view
- ✅ Records admin who rejected the request
- ✅ Parent can see rejection reason in their children list

---

### Get Children

#### Get All Related Children (Parent)

**Endpoint:** `GET /api/children/get-related`

**Description:** Get all children related to authenticated parent (as parent or guardian).

**Request:**
```http
GET /api/children/get-related
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "children": [
    {
      "_id": "child_id",
      "arabicFullName": "نور الدین محمود",
      "fullName": "Nour El Din",
      "gender": "male",
      "birthDate": "2013-06-03T00:00:00.000Z",
      "nationalId": "31303170105673",
      "ageInOctober": 136,
      "parent": {
        "user": {
          "_id": "parent_id",
          "fullName": "Parent Name",
          "email": "parent@example.com"
        },
        "type": "father"
      },
      "schoolId": {
        "_id": "school_id",
        "name": "School Name",
        "nameAr": "اسم المدرسة"
      },
      "documents": [...],
      "createdAt": "2024-01-15T10:00:00.000Z"
    }
  ]
}
```

---

#### Get Single Child by ID

**Endpoint:** `GET /api/children/get-related/[id]`

**Description:** Get detailed information about a specific child.

**Request:**
```http
GET /api/children/get-related/694a93b4707b36f746049ffa
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "child": {
    "_id": "child_id",
    "arabicFullName": "نور الدین محمود",
    "fullName": "Nour El Din",
    "gender": "male",
    "birthDate": "2013-06-03T00:00:00.000Z",
    "nationalId": "31303170105673",
    "ageInOctober": 136,
    "schoolId": {
      "_id": "school_id",
      "name": "School Name",
      "nameAr": "اسم المدرسة",
      "logo": { "url": "logo_url" }
    },
    "documents": [...],
    "profileImage": { "url": "profile_url" },
    "createdAt": "2024-01-15T10:00:00.000Z"
  }
}
```

---

### Update Child

**Endpoint:** `PUT /api/children/get-related/[id]`

**Description:** Update child information. Only provided fields will be updated.

**Request:**
```http
PUT /api/children/get-related/694a93b4707b36f746049ffa
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body (all fields optional):**
```json
{
  "currentSchool": "New School Name",
  "desiredGrade": "Grade 6",
  "religion": "Muslim",
  "birthPlace": "Cairo",
  "specialNeeds": {
    "hasNeeds": false,
    "description": ""
  }
}
```

**Response (200 Success):**
```json
{
  "message": "Child updated successfully",
  "child": {
    "_id": "child_id",
    "currentSchool": "New School Name",
    "updatedAt": "2024-01-15T11:00:00.000Z"
  }
}
```

**Important Notes:**
- ⚠️ Do NOT send empty strings for enum fields (`religion`, `languagePreference.primaryLanguage`)
- ⚠️ `ageInOctober` is **read-only** - it's automatically calculated from `birthDate`
- ✅ Only updates fields that are provided in the request

---

### Upload Documents

**Endpoint:** `PUT /api/children/get-related/[id]/upload`

**Description:** Upload profile image or document for a child.

**Request:**
```http
PUT /api/children/get-related/694a93b4707b36f746049ffa/upload
Authorization: Bearer <token>
Content-Type: multipart/form-data

Form Data:
- file: [image or PDF file] (required)
- label: "Document Name" (optional, for documents only)
- type: "profile" or "document" (required)
```

**Response (200 Success):**
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
        "label": "Document Name"
      }
    ]
  }
}
```

---

## 📋 Common Workflows

### Workflow 1: Add Child with Automatic Data Extraction (Recommended)

**Use Case:** Parent wants to add a child using birth certificate with automatic data extraction.

**Steps:**
1. **Extract Data from Birth Certificate**
   ```javascript
   const formData = new FormData();
   formData.append('birthCertificate', file);
   
   const response = await fetch('/api/children/extract-birth-certificate', {
     method: 'POST',
     headers: { 'Authorization': `Bearer ${token}` },
     body: formData
   });
   
   const { extractedData, birthCertificateImage } = await response.json();
   ```

2. **Auto-fill Form with Extracted Data**
   ```javascript
   const formData = {
     arabicFullName: extractedData.arabicFullName,
     fullName: extractedData.fullName,
     gender: extractedData.gender,
     birthDate: extractedData.birthDate,
     nationalId: extractedData.nationalId,
     nationality: extractedData.nationality || 'Egyptian',
     birthPlace: extractedData.birthPlace,
     religion: extractedData.religion,
     birthCertificate: extractedData.birthCertificateImage
   };
   ```

3. **Add Child**
   ```javascript
   const response = await fetch('/api/children', {
     method: 'POST',
     headers: {
       'Authorization': `Bearer ${token}`,
       'Content-Type': 'application/json'
     },
     body: JSON.stringify(formData)
   });
   
   const { children } = await response.json();
   ```

**✅ Benefits:**
- Fast and accurate data entry
- Automatic age calculation
- Birth certificate automatically saved

---

### Workflow 2: Add Child with Parent Identity Validation

**Use Case:** Parent needs to verify their identity before adding child (two-step validation).

**Steps:**
1. **Upload Parent National ID Card**
   ```javascript
   const parentFormData = new FormData();
   parentFormData.append('birthCertificate', parentIdFile);
   
   const parentResponse = await fetch('/api/children/extract-birth-certificate', {
     method: 'POST',
     headers: { 'Authorization': `Bearer ${token}` },
     body: parentFormData
   });
   
   const { extractedData: parentData } = await parentResponse.json();
   const parentNationalId = parentData.nationalId; // Store this
   ```

2. **Upload Child Birth Certificate**
   ```javascript
   const childFormData = new FormData();
   childFormData.append('birthCertificate', childCertificateFile);
   
   const childResponse = await fetch('/api/children/extract-birth-certificate', {
     method: 'POST',
     headers: { 'Authorization': `Bearer ${token}` },
     body: childFormData
   });
   
   const { extractedData: childData } = await childResponse.json();
   ```

3. **Validate Parent ID**
   ```javascript
   const fatherId = childData.fatherNationalId;
   const motherId = childData.motherNationalId;
   
   const isValid = parentNationalId === fatherId || parentNationalId === motherId;
   
   if (!isValid) {
     // Show error
     alert(`Parent ID mismatch!\nYour ID: ${parentNationalId}\nFather ID: ${fatherId}\nMother ID: ${motherId}`);
     return;
   }
   ```

4. **Add Child (same as Workflow 1, Step 3)**

**✅ Benefits:**
- Ensures parent is authorized to add the child
- Prevents unauthorized child registration
- Shows clear error messages if IDs don't match

---

### Workflow 3: Manual Child Entry

**Use Case:** Parent wants to enter data manually (no document upload).

**Steps:**
1. **Fill Form Manually**
   ```javascript
   const formData = {
     arabicFullName: "أحمد محمد",
     fullName: "Ahmed Mohamed",
     gender: "male",
     birthDate: "2015-05-15",
     nationalId: "12345678901234",
     nationality: "Egyptian",
     religion: "Muslim"
   };
   ```

2. **Add Child**
   ```javascript
   const response = await fetch('/api/children', {
     method: 'POST',
     headers: {
       'Authorization': `Bearer ${token}`,
       'Content-Type': 'application/json'
     },
     body: JSON.stringify(formData)
   });
   ```

**✅ Benefits:**
- No document required
- Full control over data entry
- Works even if OCR fails

---

## ⚠️ Error Handling

### Common Error Responses

#### 400 Bad Request
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

#### 403 Forbidden
```json
{
  "message": "Unauthorized"
}
```

#### 409 Conflict (National ID exists)
```json
{
  "message": "Child with this national ID already exists",
  "existingChildId": "child_id"
}
```

#### 503 Service Unavailable (AI Error)
```json
{
  "message": "OCR extraction failed. Please enter data manually.",
  "error": "Error details",
  "canContinue": true
}
```

### Error Handling Best Practices

```javascript
try {
  const response = await fetch('/api/children/extract-birth-certificate', {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
    body: formData
  });
  
  if (!response.ok) {
    const error = await response.json();
    
    if (response.status === 409) {
      // National ID already exists
      alert(`Child with National ID ${error.existingChildId} already exists`);
    } else if (response.status === 503 && error.canContinue) {
      // OCR failed but can continue manually
      alert('Automatic extraction failed. Please enter data manually.');
      // Show manual form
    } else {
      // Other errors
      alert(error.message || 'An error occurred');
    }
    return;
  }
  
  const data = await response.json();
  // Process extracted data
  
} catch (error) {
  console.error('Network error:', error);
  alert('Network error. Please check your connection.');
}
```

---

## 🔑 Key Features

### Automatic Data Extraction
- ✅ Detects document type (birth_certificate, national_id, passport)
- ✅ Extracts child's National ID from top of document
- ✅ Extracts both father's and mother's National IDs
- ✅ Converts Arabic-Indic numerals to standard digits
- ✅ Handles Arabic written years (e.g., "عام الفان و ثلاثه عشر" = 2013)
- ✅ Combines child name + father name for full Arabic name
- ✅ Extracts birth place, religion, gender automatically

### Age Calculation
- ✅ Automatically calculates `ageInOctober` (in months) from `birthDate`
- ✅ Field is **read-only** - cannot be edited manually
- ✅ Calculated as: age in months as of October 1st of current/next year

### Parent ID Validation
- ✅ Two-step flow: Upload parent ID → Upload child certificate
- ✅ Validates parent ID matches father OR mother ID
- ✅ Shows clear error messages if mismatch

### Document Management
- ✅ Birth certificate automatically saved to `documents` array
- ✅ Supports profile image upload
- ✅ Supports additional document uploads
- ✅ Files stored in ImageKit

---

## 📝 Field Reference

### Child Model Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `arabicFullName` | String | Yes* | Full name in Arabic |
| `fullName` | String | Yes* | Full name in English |
| `gender` | String | Yes | "male", "female", or "other" |
| `birthDate` | Date | Yes | Format: "YYYY-MM-DD" |
| `nationalId` | String | No | 14-digit National ID |
| `nationality` | String | No | Defaults to "Egyptian" |
| `religion` | String | No | "Muslim", "Christian", or "Other" |
| `birthPlace` | String | No | Place of birth |
| `ageInOctober` | Number | Auto | Age in months (read-only, calculated) |
| `desiredGrade` | String | No | Desired grade level |
| `currentSchool` | String | No | Current school name |
| `schoolId` | ObjectId | No | School ID if transferring |

*At least one of `arabicFullName` or `fullName` is required.
 
---

## 🎯 Quick Reference

### Most Common Endpoints

| Endpoint | Method | Use Case |
|----------|--------|----------|
| `/api/children/extract-birth-certificate` | POST | Extract data from documents |
| `/api/children` | POST | Add new child |
| `/api/children/get-related` | GET | Get all children |
| `/api/children/get-related/[id]` | GET | Get single child |
| `/api/children/get-related/[id]` | PUT | Update child |
| `/api/children/get-related/[id]/upload` | PUT | Upload documents |

---

## 📞 Support

For API issues or questions:
- Check error responses for detailed messages
- Verify authentication token is valid
- Ensure required fields are provided
- Check network connectivity

---

_Last updated: January 2025_