# Derasy Platform API Documentation

> **📖 Documentation Files:**
> - **[API-README.md](./API-README.md)** - Quick start guide and common use cases
> - **[API-WORKFLOWS.md](./API-WORKFLOWS.md)** - Step-by-step workflows and code examples
> - **This file** - Complete API reference

---

## 📚 Table of Contents
1. [Quick Start Guide](#quick-start-guide)
2. [Authentication](#authentication)
3. [User & Account Management](#user--account-management-apis)
   - [Check User Existence](#check-user-existence)
4. [Children Management APIs](#children-management-apis)
   - [Add Child with Birth Certificate Extraction](#add-child-with-birth-certificate-extraction)
   - [Two-Step Document Upload Flow](#two-step-document-upload-flow)
   - [OTP Verification Flow for Existing Children](#otp-verification-flow-for-existing-children)
   - [Non-Egyptian Child Requests Flow](#non-egyptian-child-requests-flow)
   - [Admin: Non-Egyptian Child Requests Management](#admin-non-egyptian-child-requests-management)
   - [Get Children](#get-children)
   - [Update Child](#update-child)
   - [Upload Documents](#upload-documents)
5. [Admission Flow APIs](#admission-flow-apis)
   - [Get AI School Suggestions](#get-ai-school-suggestions)
   - [Submit Admission Application](#submit-admission-application)
   - [Reorder Applications](#reorder-applications)
   - [Get Parent's Applications](#get-parents-applications)
   - [Get School Applications](#get-school-applications)
   - [Get Single Application Detail](#get-single-application-detail)
   - [Set Interview Date](#set-interview-date)
   - [Custom Admission Forms APIs](#custom-admission-forms-apis)
6. [School Management & Sales APIs](#school-management--sales-apis)
   - [Sales: Register New School (Onboarding)](#sales-register-new-school-onboarding)
   - [School: Get Quick Statistics](#school-get-quick-statistics)
   - [School: Check User Access Permissions](#school-check-user-access-permissions)
7. [Common Workflows](#common-workflows)
8. [Error Handling](#error-handling)
9. [Wallet Management APIs](#wallet-management-apis)
10. [Reports & Analytics APIs](#reports--analytics-apis)
   - [School Comprehensive AI Report](#school-comprehensive-ai-report)
   - [List Custom Report Templates](#list-custom-report-templates)
   - [Manage Report Templates](#manage-report-templates)
11. [Chat & Messaging APIs](#chat--messaging-apis)
   - [List Conversations](#list-conversations)
   - [Create Conversation](#create-conversation)
   - [Get Messages](#get-messages)
   - [Send Message](#send-message)
12. [Admission Follow-Up APIs](#admission-follow-up-apis)
   - [Get Application Events](#get-application-events)
   - [Add Application Event](#add-application-event)
   - [Parent: Reply to Event](#parent-reply-to-event)
13. [Teachers Management APIs](#teachers-management-apis)
   - [List Teachers](#list-teachers)
   - [Create Teacher](#create-teacher)
   - [Get Single Teacher](#get-single-teacher-detail)
   - [Update Teacher](#update-teacher)
   - [Update Teacher Timetable](#update-teacher-timetable)
   - [Delete Teacher](#delete-teacher)
14. [Store & E-commerce APIs](#store--e-commerce-apis)
   - [Cart Management](#cart-management)
   - [Orders & Checkout](#orders--checkout)
   - [Products](#products)

---

15. [Notifications APIs](#notifications-apis)
   - [List Notifications](#list-notifications)
   - [Mark All Read](#mark-all-read)
   - [Create Notification (System)](#create-notification-system)

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
  "user": {
    "_id": "user_id",
    "role": "parent",
    "email": "user@example.com",
    "username": "user123"
  }
}
```

### Validate Token
```http
GET /api/me
Authorization: Bearer <token>
```
**Response:**
```json
{
  "user": { ... }
}
```

---

## 👤 User & Account Management APIs

### Check User Existence

**Endpoint:** `POST /api/users/check`

**Description:** Check if a user already exists in the system by email or phone number. Useful for validation before creating new accounts during onboarding.

**Request:**
```http
POST /api/users/check
Content-Type: application/json

{
  "email": "user@example.com",
  "phone": "01234567890"
}
```

**Response (200 Success - Found):**
```json
{
  "exists": true,
  "message": "User already exists: user@example.com"
}
```

**Response (200 Success - Not Found):**
```json
{
  "exists": false
}
```

**Notes:**
- ✅ Checks against both `email` and `phone` fields.
- ✅ Returns `exists: true` if either matches.

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
- ✅ Handles Arabic written years (e.g., "عام الفان و ثلاثه عشر" = 2013)
- ✅ Calculates age in coming October automatically
- ✅ Combines child name + father name for full Arabic name
- ✅ Validates National ID uniqueness before extraction completes
- ✅ **New:** Supports passport extraction for non-Egyptian children.

---

### Extract National ID Data (Egyptian)

**Endpoint:** `POST /api/children/extract-national-id`

**Description:** Extracts data from Egyptian National ID card (Front and/or Back) using Google Gemini AI. Both front and back images can be provided for better accuracy.

**Request:**
```http
POST /api/children/extract-national-id
Authorization: Bearer <token>
Content-Type: multipart/form-data

Form Data:
- nationalIdFront: [front_image_file] (optional)
- nationalIdBack: [back_image_file] (optional)
- nationalId: [image_file] (optional, backward compatibility, treated as front)
```

**Response (200 Success):**
```json
{
  "success": true,
  "extractedData": {
    "nationalId": "29001011234567",
    "fullName": "Name in English",
    "arabicFullName": "الاسم بالعربي",
    "birthDate": "1990-01-01",
    "gender": "male",
    "religion": "Muslim",
    "address": "123 Street Name, City",
    "birthPlace": "Cairo",
    "nationalIdImages": {
       "front": {
         "url": "https://ik.imagekit.io/...",
         "publicId": "...",
         "uploadedAt": "2024-01-01T10:00:00.000Z"
       },
       "back": {
         "url": "https://ik.imagekit.io/...",
         "publicId": "...",
         "uploadedAt": "2024-01-01T10:00:00.000Z"
       }
    },
    "nationalIdImage": { 
      "url": "https://ik.imagekit.io/..." 
    }
  },
  "extractedText": "Raw extracted text...",
  "documentType": "national_id"
}
```

**Response (503 Service Unavailable):**
```json
{
  "message": "OCR extraction failed. Please enter data manually.",
  "error": "Error details",
  "canContinue": true
}
```

**Notes:**
- ✅ Supports both front and back images
- ✅ Combines text info from both images
- ✅ Extracts names (Arabic/English), Address, ID number, Birth date, etc.
- ✅ Handles rate limits gracefully

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
- `birthCertificate` (file or object with `data`/`url`)
- `parentPassport` (file or object, for non-Egyptian)
- `childPassport` (file or object, for non-Egyptian)
- `parentNationalIdCard` (file or object, for Egyptian)

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
      "schoolId": {
        "_id": "school_id", 
        "name": "School Name",
        "nameAr": "اسم المدرسة",
        "logo": {
          "url": "..."
        }
      },
      "grade": {
        "_id": "grade_id",
        "name": "Grade 1",
        "nameAr": "الاول الابتدائي"
      }
    }
  ],
  "count": 1
}
```

### Note on Performance
The `GET /api/children/get-related` endpoint is optimized to return only essential data for the list view. It specifically populates `schoolId` and `grade` but omits heavy nested relations like `parent.user`, `sections`, etc., to ensure fast loading times.

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

## 📚 Admission Flow APIs

### Get AI School Suggestions

**Endpoint:** `POST /api/schools/suggest-three`

**Description:** Uses Google Gemini AI to analyze a child's profile against a list of schools and user preferences to suggest the top 3 most suitable schools.

**Request:**
```http
POST /api/schools/suggest-three
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "child": {
    "_id": "child_id",
    "fullName": "Student Name",
    "gender": "male",
    "ageInOctober": 68
    // ... complete child object
  },
  "schools": [
    // Array of school objects to analyze
    {
      "_id": "school_id_1",
      "name": "School A",
      "admissionFee": { "amount": 50000 },
      "type": "National"
    },
    {
      "_id": "school_id_2",
      "name": "School B",
      "admissionFee": { "amount": 80000 },
      "type": "International"
    }
  ],
  "preferences": {
    "minFee": 20000,
    "maxFee": 60000,
    "busFeeMax": 15000,
    "zone": "Nasr City",
    "type": "National",
    "coed": "mixed",
    "language": "English"
  }
}
```

**Preferences Object Details:**
- `minFee` (Number, optional): Minimum tuition fee preference.
- `maxFee` (Number, optional): Maximum tuition fee preference.
- `busFeeMax` (Number, optional): Maximum bus subscription fee.
- `zone` (String, optional): Filter by school zone/area.
- `type` (String, optional): School type (e.g., "National", "International", "American").
- `coed` (String, optional): "mixed" for Co-ed, "single" for Segregated.
- `language` (String, optional): Primary language preference.

**Response (200 Success):**
```json
{
  "message": "تم إنشاء الترشيحات بنجاح",
  "markdown": "## تحليل الذكاء الاصطناعي\n\nبناءً على ملف الطالب...\n* **مدرسة المستقبل**: لأنها تناسب الميزانية...",
  "html": "<h2>تحليل الذكاء الاصطناعي</h2>...",
  "suggestedIds": ["school_id_1", "school_id_5", "school_id_8"]
}
```

**Response (429 Too Many Requests):**
```json
{
  "message": "عذراً، المساعد الذكي مشغول جداً حالياً..."
}
```

**Notes:**
- ✅ Returns analysis in Egyptian Arabic (Markdown & HTML).
- ✅ Prioritizes user hard constraints (Fees, Zone) in the AI prompt.
- ✅ Returns raw list of suggested School IDs for UI highlighting.

---

### Submit Admission Application

**Endpoint:** `POST /api/admission/apply`

**Description:** Submit an admission application for a child to one or more schools. The system will create a "pending" application for the first school and "draft" applications for others. Deducts the *highest* admission fee among the selected schools from the parent's wallet.

**Request:**
```http
POST /api/admission/apply
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
      "name": "Primary Choice School",
      "admissionFee": { "amount": 500 }
    },
    {
      "_id": "school_id_2",
      "name": "Secondary Choice School",
      "admissionFee": { "amount": 300 }
    }
  ]
}
```

**Required Fields:**
- `childId` - The ID of the child applying
- `selectedSchools` - Array of school objects. The first one will be the primary application.

**Response (200 Success):**
```json
{
  "message": "✅ تم إنشاء الطلبات بنجاح",
  "applications": [
    {
      "_id": "application_id_1",
      "status": "pending",
      "priority": 0,
      "payment": { "isPaid": true, "amount": 500 }
      // ...
    },
    {
      "_id": "application_id_2",
      "status": "draft",
      "priority": 1,
      "payment": { "isPaid": true, "amount": 0 }
      // ...
    }
  ]
}
```

**Response (400 Bad Request - Insufficient Balance):**
```json
{
  "message": "رصيدك غير كافٍ. تحتاج إلى 500 جنيه على الأقل.",
  "details": {
    "currentBalance": 200,
    "requiredAmount": 500,
    "shortfall": 300
  }
}
```

---

### Reorder Applications

**Endpoint:** `PUT /api/applications/reorder`

**Description:** Reorder the priority of a parent's applications. Useful for changing which school is the primary choice.

**Request:**
```http
PUT /api/applications/reorder
Authorization: Bearer <token>
Content-Type: application/json

{
  "orderedIds": ["app_id_2", "app_id_1", "app_id_3"]
}
```

**Response (200 Success):**
```json
{
  "message": "Order updated successfully"
}
```

---

### Get Parent's Applications

**Endpoint:** `GET /api/me/applications`

**Description:** Get all admission applications submitted by the authenticated parent.

**Request:**
```http
GET /api/me/applications
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "applications": [
    {
      "_id": "application_id",
      "child": { ... },
      "school": { ... },
      "status": "pending",
      "priority": 0,
      "submittedAt": "2025-01-15T10:00:00.000Z"
    }
  ]
}
```

---

### Get School Applications

**Endpoint:** `GET /api/schools/my/[id]/admission-forms`

**Description:** Get all admission applications for a specific school (school owner/moderator/admin only). Returns only non-draft applications.

**Request:**
```http
GET /api/schools/my/school_id/admission-forms
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "applications": [ ... ],
  "school": { ... },
  "totalApplications": 15,
  "byStatus": {
    "pending": 5,
    "under_review": 3,
    "accepted": 5,
    "rejected": 2
  }
}
```

---

### Get Single Application Detail

**Endpoint:** `GET /api/me/applications/school/my/[applicationId]`

**Description:** Get detailed information about a specific application (school owner/moderator/admin only).

**Request:**
```http
GET /api/me/applications/school/my/application_id
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "_id": "application_id",
  "parent": { ... },
  "child": { ... },
  "school": { ... },
  "status": "under_review",
  "interview": { ... },
  "events": [ ... ]
}
```

---

### Set Interview Date

**Endpoint:** `PUT /api/me/applications/school/my/[applicationId]`

**Description:** Set or update the interview date for an application. Automatically updates status to `under_review` and sends email notification to parent.

**Request:**
```http
PUT /api/me/applications/school/my/application_id
Authorization: Bearer <token>
Content-Type: application/json

{
  "interviewDate": "2025-02-20",
  "interviewTime": "11:30 AM",
  "location": "Main Office",
  "notes": "Bring original birth certificate"
}
```

**Response (200 Success):**
```json
{
  "message": "تم تحديد موعد المقابلة بنجاح",
  "application": { ... }
}
```

---

### Custom Admission Forms APIs

These APIs manage the school's own customized admission forms (builder-based).

#### List School Custom Forms
**Endpoint:** `GET /api/schools/my/[id]/admission-forms/templates`
*(Note: Route may vary, please verify school-side form listing)*

#### Get Custom Form Details
**Endpoint:** `GET /api/schools/my/[id]/admission-forms/[formId]`

#### Submit Custom Form
**Endpoint:** `POST /api/schools/my/[id]/admission-forms/[formId]/submissions`

#### View Form Submissions
**Endpoint:** `GET /api/schools/my/[id]/admission-forms/[formId]/submissions`

#### Manage Submission Status
**Endpoint:** `PUT /api/schools/my/[id]/admission-forms/[formId]/submissions/[submissionId]`
**Body:** `{ "status": "approved", "notes": "..." }`

**Response (200 Success):**
```json
{
  "applications": [
    {
      "_id": "application_id",
      "parent": {
        "_id": "parent_user_id",
        "name": "Parent Name",
        "email": "parent@example.com",
        "phone": "01234567890"
      },
      "child": {
        "_id": "child_id",
        "fullName": "Child Name",
        "arabicFullName": "اسم الطفل",
        "birthDate": "2013-06-03T00:00:00.000Z",
        "currentSchool": "Previous School",
        "desiredGrade": "Grade 5"
      },
      "status": "pending",
      "applicationType": "transfer",
      "payment": {
        "isPaid": true,
        "amount": 500
      },
      "submittedAt": "2025-01-15T10:00:00.000Z"
    }
  ],
  "count": 1
}
```

**Response (403 Forbidden):**
```json
{
  "message": "Access denied: You do not have permission to view applications for this school"
}
```

**Notes:**
- ✅ Only school owners, moderators, and admins can access
- ✅ Supports filtering by status
- ✅ Returns parent and child information

---

### Get Single Application

**Endpoint:** `GET /api/me/applications/school/my/[id]`

**Description:** Get detailed information about a specific application (school admin or parent).

**Request:**
```http
GET /api/me/applications/school/my/application_id
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "_id": "application_id",
  "parent": {
    "_id": "parent_user_id",
    "name": "Parent Name",
    "email": "parent@example.com",
    "phone": "01234567890"
  },
  "child": {
    "_id": "child_id",
    "fullName": "Child Name",
    "arabicFullName": "اسم الطفل",
    "birthDate": "2013-06-03T00:00:00.000Z",
    "gender": "male",
    "nationalId": "31303170105673",
    "currentSchool": "Previous School",
    "desiredGrade": "Grade 5",
    "documents": [
      {
        "url": "https://imagekit.io/...",
        "label": "birth_certificate",
        "source": "uploaded"
      }
    ]
  },
  "school": {
    "_id": "school_id",
    "name": "School Name",
    "nameAr": "اسم المدرسة",
    "type": "private",
    "admissionFee": {
      "amount": 500
    }
  },
  "status": "under_review",
  "applicationType": "new_student",
  "interview": {
    "date": "2025-02-20T00:00:00.000Z",
    "time": "11:30 AM",
    "location": "Main Office - First Floor",
    "notes": "Please bring all required documents"
  },
  "preferredInterviewSlots": [
    {
      "date": "2025-02-15T00:00:00.000Z",
      "timeRange": {
        "from": "10:00 AM",
        "to": "12:00 PM"
      }
    }
  ],
  "payment": {
    "isPaid": true,
    "amount": 500,
    "paidAt": "2025-01-15T10:00:00.000Z",
    "method": "wallet"
  },
  "events": [
    {
      "_id": "event_id",
      "type": "interview_scheduled",
      "title": "تم تحديد موعد المقابلة",
      "description": "تم تحديد موعد المقابلة في 20 فبراير 2025 الساعة 11:30 AM",
      "date": "2025-01-16T10:00:00.000Z",
      "createdBy": {
        "_id": "admin_user_id",
        "name": "Admin Name"
      }
    }
  ],
  "submittedAt": "2025-01-15T10:00:00.000Z",
  "updatedAt": "2025-01-16T10:00:00.000Z"
}
```

**Response (403 Forbidden):**
```json
{
  "message": "Access denied: You do not have permission to view this application"
}
```

**Notes:**
- ✅ School admins can view applications for their schools
- ✅ Parents can view their own applications
- ✅ Includes full child and parent information
- ✅ Includes interview details if scheduled
- ✅ Includes events/notes timeline

---

### Set Interview Date

**Endpoint:** `PUT /api/me/applications/school/my/[id]`

**Description:** Set interview date for an application (school admin only). Automatically creates an event and sends email notification to parent.

**Request:**
```http
PUT /api/me/applications/school/my/application_id
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "date": "2025-02-20",
  "time": "11:30 AM",
  "location": "Main Office - First Floor",
  "notes": "Please bring all required documents"
}
```

**Alternative Field Names (also supported):**
```json
{
  "interviewDate": "2025-02-20",
  "interviewTime": "11:30 AM",
  "location": "Main Office - First Floor",
  "notes": "Please bring all required documents"
}
```

**Required Fields:**
- `date` or `interviewDate` - Interview date in YYYY-MM-DD format
- `time` or `interviewTime` - Interview time (e.g., "11:30 AM")

**Optional Fields:**
- `location` - Interview location
- `notes` - Additional notes for parent

**Response (200 Success):**
```json
{
  "message": "تم تحديد موعد المقابلة بنجاح",
  "application": {
    "_id": "application_id",
    "interview": {
      "date": "2025-02-20T00:00:00.000Z",
      "time": "11:30 AM",
      "location": "Main Office - First Floor",
      "notes": "Please bring all required documents"
    },
    "status": "under_review",
    "events": [
      {
        "type": "interview_scheduled",
        "title": "تم تحديد موعد المقابلة",
        "description": "تم تحديد موعد المقابلة في 20 فبراير 2025 الساعة 11:30 AM في Main Office - First Floor",
        "date": "2025-01-16T10:00:00.000Z",
        "createdBy": "admin_user_id"
      }
    ]
  }
}
```

**Response (400 Bad Request):**
```json
{
  "message": "يرجى إدخال تاريخ ووقت المقابلة"
}
```

**Notes:**
- ✅ Automatically changes application status to `under_review`
- ✅ Creates `interview_scheduled` event automatically
- ✅ Sends email notification to parent with interview details
- ✅ Email includes formatted date, time, location, and notes

---

### Application Events/Notes

**Endpoint:** `POST /api/me/applications/school/my/[id]/events`

**Description:** Add an event/note to an application's follow-up timeline (school admin only).

**Request:**
```http
POST /api/me/applications/school/my/application_id/events
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "type": "note_added",
  "title": "تم التواصل مع ولي الأمر",
  "description": "تم التواصل مع ولي الأمر عبر الهاتف وتم التأكيد على الحضور",
  "date": "2025-01-17",
  "metadata": {
    "contactMethod": "phone",
    "phoneNumber": "01234567890"
  }
}
```

**Event Types:**
- `note_added` - General note
- `interview_scheduled` - Interview date set (usually auto-created)
- `interview_attended` - Parent attended interview
- `interview_missed` - Parent missed interview
- `status_changed` - Application status changed (usually auto-created)
- `parent_contacted` - Contacted parent
- `document_requested` - Requested document from parent
- `document_received` - Received document from parent
- `other` - Other event type

**Required Fields:**
- `type` - Event type (must be one of the above)
- `title` - Event title

**Optional Fields:**
- `description` - Detailed description
- `date` - Event date (defaults to current date)
- `metadata` - Additional metadata object

**Response (200 Success):**
```json
{
  "message": "تم إضافة الحدث بنجاح",
  "event": {
    "_id": "event_id",
    "type": "note_added",
    "title": "تم التواصل مع ولي الأمر",
    "description": "تم التواصل مع ولي الأمر عبر الهاتف وتم التأكيد على الحضور",
    "date": "2025-01-17T00:00:00.000Z",
    "createdBy": {
      "_id": "admin_user_id",
      "name": "Admin Name"
    },
    "metadata": {
      "contactMethod": "phone",
      "phoneNumber": "01234567890"
    }
  },
  "application": {
    "_id": "application_id",
    "events": [...]
  }
}
```

**Response (400 Bad Request):**
```json
{
  "message": "يرجى إدخال نوع الحدث والعنوان"
}
```

---

**Endpoint:** `GET /api/me/applications/school/my/[id]/events`

**Description:** Get all events/notes for an application (school admin or parent).

**Request:**
```http
GET /api/me/applications/school/my/application_id/events
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "events": [
    {
      "_id": "event_id",
      "type": "interview_scheduled",
      "title": "تم تحديد موعد المقابلة",
      "description": "تم تحديد موعد المقابلة في 20 فبراير 2025 الساعة 11:30 AM",
      "date": "2025-01-16T10:00:00.000Z",
      "createdBy": {
        "_id": "admin_user_id",
        "name": "Admin Name",
        "email": "admin@example.com",
        "role": "school_owner"
      },
      "metadata": {
        "interviewDate": "2025-02-20T00:00:00.000Z",
        "interviewTime": "11:30 AM",
        "location": "Main Office"
      }
    },
    {
      "_id": "event_id_2",
      "type": "interview_attended",
      "title": "تم حضور المقابلة",
      "description": "تم حضور ولي الأمر والطفل في الموعد المحدد للمقابلة",
      "date": "2025-02-20T11:30:00.000Z",
      "createdBy": {
        "_id": "admin_user_id",
        "name": "Admin Name"
      }
    }
  ]
}
```

**Notes:**
- ✅ Events are sorted by date (newest first)
- ✅ Each event includes creator information
- ✅ Parents can view events for their applications
- ✅ School admins can view and add events

---

### Update Application Status

**Endpoint:** `PUT /api/me/applications/school/my/[id]/status`

**Description:** Update application status (school admin only). Automatically creates a status change event.

**Request:**
```http
PUT /api/me/applications/school/my/application_id/status
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "status": "accepted",
  "note": "Application accepted after successful interview"
}
```

**Required Fields:**
- `status` - New status: "pending", "under_review", "recommended", "accepted", "rejected", or "draft"

**Optional Fields:**
- `note` - Additional note for the status change

**Response (200 Success):**
```json
{
  "message": "تم تحديث الحالة بنجاح",
  "application": {
    "_id": "application_id",
    "status": "accepted",
    "events": [
      {
        "type": "status_changed",
        "title": "تغيير الحالة من قيد المراجعة إلى تم القبول",
        "description": "Application accepted after successful interview",
        "date": "2025-01-18T10:00:00.000Z",
        "createdBy": "admin_user_id",
        "metadata": {
          "oldStatus": "under_review",
          "newStatus": "accepted"
        }
      }
    ]
  }
}
```

**Response (400 Bad Request):**
```json
{
  "message": "حالة غير صالحة"
}
```

**Response (403 Forbidden):**
```json
{
  "message": "Access denied: You do not have permission to modify this application"
}
```

**Notes:**
- ✅ Automatically creates `status_changed` event
- ✅ Event includes old and new status in metadata
- ✅ Only school owners, moderators, and admins can update status
- ✅ Status change is logged in events timeline

---

## 🏫 School Management & Sales APIs

### Sales: Register New School (Onboarding)

**Endpoint:** `POST /api/sales/onboarding`

**Description:** Performs a complete onboarding of a new school, including creating or updating the School Owner and Moderator accounts, and initializing the school record.

**Request:**
```http
POST /api/sales/onboarding
Authorization: Bearer <sales_token>
Content-Type: application/json

{
  "schoolData": {
    "name": "School Name",
    "type": "General",
    "location": { ... },
    "feesDetails": { ... }
  },
  "ownerData": {
    "name": "Owner Name",
    "email": "owner@example.com",
    "phone": "01012345678",
    "password": "securepassword"
  },
  "moderatorData": {
    "name": "Moderator Name",
    "email": "mod@example.com",
    "phone": "01087654321",
    "password": "securepassword"
  },
  "configData": {
    "approved": true,
    "showInSearch": true
  }
}
```

**Response (201 Created):**
```json
{
  "message": "School created successfully",
  "schoolId": "new_school_id"
}
```

---

### School: Get Quick Statistics

**Endpoint:** `GET /api/schools/my/[id]/quick-stats`

**Description:** Returns a summary of key metrics for a school. Requires Owner, Moderator, or Admin permissions.

**Request:**
```http
GET /api/schools/my/school_id/quick-stats
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "stats": {
    "activeStudents": 150,
    "applications": 45,
    "tasks": 12
  }
}
```

**Notes:**
- **activeStudents**: Total children enrolled in the school.
- **applications**: Total admission applications (excluding drafts).
- **tasks**: Applications pending review (status: `pending` or `under_review`).

---

### School: Get Quick Statistics

**Endpoint:** `GET /api/schools/my/[id]/quick-stats`

**Description:** Get key metrics for the school moderator dashboard, including student count, total applications, and pending tasks.

**Request:**
```http
GET /api/schools/my/school_id/quick-stats
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "stats": {
    "activeStudents": 150,
    "applications": 45,
    "tasks": 12
  }
}
```

---

### School: Check User Access Permissions

**Endpoint:** `GET /api/schools/my/[id]/check-access`

**Description:** Verifies if the authenticated user has permission to manage the specified school and returns their role-based permissions.

**Request:**
```http
GET /api/schools/my/school_id/check-access
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "authorized": true,
  "isOwner": false,
  "isModerator": true,
  "isAdmin": false,
  "isSales": false,
  "school": {
    "_id": "school_id",
    "name": "School Name",
    "nameAr": "اسم المدرسة"
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

### Workflow 4: Submit Admission Application

**Use Case:** Parent wants to apply for their child to one or more schools.

**Steps:**
1. **Submit Application**
   ```javascript
   const response = await fetch('/api/admission/apply', {
     method: 'POST',
     headers: {
       'Authorization': `Bearer ${token}`,
       'Content-Type': 'application/json'
     },
     body: JSON.stringify({
       childId: 'child_id',
       selectedSchools: [
         { _id: 'school_id_1', name: 'School 1', admissionFee: { amount: 500 } },
         { _id: 'school_id_2', name: 'School 2', admissionFee: { amount: 300 } }
       ]
     })
   });
   
   const { applications } = await response.json();
   ```

2. **Check Application Status**
   ```javascript
   const response = await fetch('/api/me/applications', {
     headers: { 'Authorization': `Bearer ${token}` }
   });
   
   const { applications } = await response.json();
   ```

**✅ Benefits:**
- Automatic highest fee wallet deduction
- First school gets "pending" status, others "draft"
- Email notification to primary school
- Full application tracking

---

### Workflow 5: School Admin - Review Application

**Use Case:** School admin wants to review and manage an application.

**Steps:**
1. **Get Application Details**
   ```javascript
   const response = await fetch(`/api/me/applications/school/my/${applicationId}`, {
     headers: { 'Authorization': `Bearer ${token}` }
   });
   
   const application = await response.json();
   ```

2. **Set Interview Date**
   ```javascript
   const response = await fetch(`/api/me/applications/school/my/${applicationId}`, {
     method: 'PUT',
     headers: {
       'Authorization': `Bearer ${token}`,
       'Content-Type': 'application/json'
     },
     body: JSON.stringify({
       interviewDate: '2025-02-20',
       interviewTime: '11:30 AM',
       location: 'Main Office',
       notes: 'Bring required documents'
     })
   });
   ```

3. **Add Event/Note**
   ```javascript
   const response = await fetch(`/api/me/applications/school/my/${applicationId}/events`, {
     method: 'POST',
     headers: {
       'Authorization': `Bearer ${token}`,
       'Content-Type': 'application/json'
     },
     body: JSON.stringify({
       type: 'interview_attended',
       title: 'تم حضور المقابلة',
       description: 'تم حضور ولي الأمر والطفل في الموعد المحدد'
     })
   });
   ```

4. **Update Status**
   ```javascript
   const response = await fetch(`/api/me/applications/school/my/${applicationId}/status`, {
     method: 'PUT',
     headers: {
       'Authorization': `Bearer ${token}`,
       'Content-Type': 'application/json'
     },
     body: JSON.stringify({
       status: 'accepted',
       note: 'Application accepted after successful interview'
     })
   });
   ```

**✅ Benefits:**
- Complete application management
- Event tracking for follow-up
- Automatic email notifications
- Status change logging

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
| `/api/users/check` | POST | Check if user exists (email/phone) |
| `/api/sales/onboarding` | POST | New school registration (Sales) |
| `/api/schools/my/[id]/quick-stats` | GET | School summary metrics |
| `/api/schools/my/[id]/check-access` | GET | Verify permissions for a school |
| `/api/children/extract-birth-certificate` | POST | Extract data from documents |
| `/api/children` | POST | Add new child |
| `/api/children/get-related` | GET | Get all children |
| `/api/children/get-related/[id]` | GET | Get single child |
| `/api/children/get-related/[id]` | PUT | Update child |
| `/api/children/get-related/[id]/upload` | PUT | Upload documents |
| `/api/admission/apply` | POST | Submit admission application |
| `/api/applications/reorder` | PUT | Reorder parent applications |
| `/api/me/applications` | GET | Get parent's applications |
| `/api/schools/my/[id]/admission-forms` | GET | Get school applications |
| `/api/me/applications/school/my/[id]` | GET | Get single application |
| `/api/me/applications/school/my/[id]` | PUT | Set interview date |
| `/api/me/applications/school/my/[id]/events` | POST | Add event/note |
| `/api/me/applications/school/my/[id]/events` | GET | Get application events |
| `/api/me/applications/school/my/[id]/status` | PUT | Update application status |
| `/api/bank-accounts` | GET | Active bank accounts |
| `/api/me/wallet/deposit` | POST | Deposit funds |
| `/api/me/wallet/withdraw` | POST | Withdraw funds |

---

## 💰 Wallet Management APIs

### Get Active Bank Accounts

**Endpoint:** `GET /api/bank-accounts`

**Description:** Get list of active bank accounts for manual transfers.

**Request:**
```http
GET /api/bank-accounts
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "accounts": [
    {
      "_id": "bank_id",
      "bankName": "National Bank of Egypt",
      "accountHolder": "Derasy Inc.",
      "accountNumber": "1234567890",
      "iban": "EG1234567890...",
      "branch": "Main Branch",
      "instructions": "Please include your email in transfer notes",
      "isActive": true
    }
  ]
}
```

---

### Deposit Funds (Bank Transfer)

**Endpoint:** `POST /api/me/wallet/deposit`

**Description:** Requests a deposit via manual bank transfer. The transaction is created with `pending` status until admin approval.

**Request:**
```http
POST /api/me/wallet/deposit
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "amount": 1000,
  "method": "bank_transfer",
  "bankAccountId": "bank_id_from_get_accounts",
  "attachment": {
    "url": "https://imagekit.io/...",
    "publicId": "receipt_image_id"
  }
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Deposit request submitted successfully",
  "transaction": {
    "user": "user_id",
    "type": "deposit",
    "amount": 1000,
    "method": "bank_transfer",
    "status": "pending",
    "description": "تحويل بنكي - في انتظار المراجعة",
    "createdAt": "2025-01-20T10:00:00.000Z"
  }
}
```

---

### Withdraw Funds

**Endpoint:** `POST /api/me/wallet/withdraw`

**Description:** Requests a withdrawal. The requested amount is **immediately deducted** (held) from the user's balance to prevent double-spending and tagged as `pending`. If rejected, it should be refunded manually by admin.

**Request:**
```http
POST /api/me/wallet/withdraw
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "amount": 500,
  "method": "bank_transfer",
  "details": "Account Name: John Doe\nIBAN: EG12345..."
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Withdrawal request created successfully",
  "transaction": {
    "user": "user_id",
    "type": "withdraw",
    "amount": 500,
    "status": "pending",
    "adminNote": "Account details...",
    "createdAt": "2025-01-20T10:00:00.000Z"
  },
  "newBalance": 1500
}
```

---

## 📞 Support

For API issues or questions:
- Check error responses for detailed messages
- Verify authentication token is valid
- Ensure required fields are provided
- Check network connectivity
---

## 📊 Reports & Analytics APIs

### School Comprehensive AI Report

**Endpoint:** `GET /api/schools/my/[id]/reports`

**Description:** Generates a comprehensive AI-powered report for the school, analyzing students, attendance, clinic visits, and more. Uses Google Gemini AI for qualitative analysis.

**Response (200 Success):**
```json
{
  "stats": {
    "studentsCount": 150,
    "applicationsCount": 45,
    "attendanceCount": 1200,
    "avgAttendanceRate": "0.92",
    "clinicVisitsCount": 8,
    "classroomsCount": 12,
    "studentIdCardsCount": 5,
    "eventsCount": 3
  },
  "studentsByClass": { ... },
  "markdown": "# 📊 تقرير شامل للمدرسة...",
  "html": "<h1>📊 تقرير شامل للمدرسة</h1>..."
}
```

---

### List Custom Report Templates

**Endpoint:** `GET /api/schools/my/[id]/reports/list`

**Description:** Get the list of available report templates for the school.

**Response (200 Success):**
```json
{
  "reports": [
    {
      "id": "template_id",
      "name": "إحصائيات الطلاب الجدد",
      "code": "STU_STATS_NEW",
      "category": "admission",
      "type": "list"
    }
  ]
}
```

---

### Manage Report Templates

#### Create/List Templates
**Endpoint:** `GET/POST /api/schools/my/[id]/reports/templates`

#### Update/Delete Template
**Endpoint:** `GET/PUT/DELETE /api/schools/my/[id]/reports/templates/[templateId]`

---

_Last updated: January 2024_

---

---

## 📊 Application Status Flow

```
pending → under_review → recommended → accepted
   ↓           ↓              ↓
rejected   rejected      rejected
```

**Status Descriptions:**
- `pending` - Initial status when application is submitted
- `under_review` - School is reviewing (usually after interview is scheduled)
- `recommended` - Recommended for acceptance (optional intermediate status)
- `accepted` - Application accepted
- `rejected` - Application rejected
- `draft` - Draft (not yet submitted)

**Status Transitions:**
- When interview is scheduled → status automatically changes to `under_review`
- Status can be changed directly by school admin
- Each status change creates an event in the timeline

---

## 🔔 Email Notifications

### When Interview is Scheduled
- **Recipient:** Parent
- **Subject:** "📅 تم تحديد موعد المقابلة - [School Name]"
- **Content:** Includes interview date, time, location, and notes

### When Application Status Changes
- Status changes are logged in events but don't trigger emails (can be added if needed)

---

## 📝 Application Events Timeline

Events provide a complete audit trail of application processing:

1. **Automatic Events:**
   - `interview_scheduled` - Created when interview date is set
   - `status_changed` - Created when status is updated

2. **Manual Events:**
   - `note_added` - General notes
   - `interview_attended` - Mark interview as attended
   - `interview_missed` - Mark interview as missed
   - `parent_contacted` - Record parent contact
   - `document_requested` - Request document from parent
   - `document_received` - Confirm document received
   - `other` - Other events

**Event Display:**
- Events are displayed chronologically (newest first)
- Each event shows: type, title, description, date, and creator
- Parents can view events for their applications
- School admins can view and add events

---


---

## 💬 Chat & Messaging APIs

### List Conversations

**Endpoint:** `GET /api/chat/conversations`

**Description:** Fetch a paginated list of conversations for the authenticated user, including unread message counts.

**Request:**
```http
GET /api/chat/conversations?limit=20&skip=0
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` (optional): Number of conversations to return (default: 20)
- `skip` (optional): Number of conversations to skip (default: 0)

**Response (200 Success):**
```json
{
  "conversations": [
    {
      "_id": "conversation_id",
      "type": "direct",
      "participants": [
        {
          "user": {
            "_id": "user_id",
            "name": "User Name",
            "email": "user@example.com",
            "avatar": "url",
            "isOnline": true,
            "lastSeen": "2024-01-20T10:00:00.000Z"
          },
          "lastReadAt": "2024-01-20T10:00:00.000Z"
        }
      ],
      "lastMessage": "message_id",
      "lastMessageAt": "2024-01-20T10:05:00.000Z",
      "unreadCount": 2,
      "createdAt": "2024-01-01T10:00:00.000Z",
      "updatedAt": "2024-01-20T10:05:00.000Z"
    }
  ],
  "pagination": {
    "limit": 20,
    "skip": 0,
    "hasMore": false
  }
}
```

---

### Create Conversation

**Endpoint:** `POST /api/chat/conversations`

**Description:** Create a new conversation (direct or group) or return an existing direct conversation.

**Request:**
```http
POST /api/chat/conversations
Authorization: Bearer <token>
Content-Type: application/json

{
  "participants": ["user_id_1", "user_id_2"],
  "type": "direct"
}
```

**Request Body:**
- `participants`: Array of user IDs (required)
- `type`: "direct" or "group" (default: "direct")
- `name`: Group name (required if type is "group")
- `description`: Group description (optional)

**Response (200 Success):**
```json
{
  "conversation": {
    "_id": "conversation_id",
    "type": "direct",
    "participants": [ ... ],
    "createdAt": "...",
    "updatedAt": "..."
  },
  "isNew": true
}
```

---

### Get Messages

**Endpoint:** `GET /api/chat/conversations/[id]/messages`

**Description:** Fetch paginated messages for a specific conversation.

**Request:**
```http
GET /api/chat/conversations/[conversation_id]/messages?limit=50&skip=0
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` (optional): (default: 50)
- `skip` (optional): (default: 0)

**Response (200 Success):**
```json
{
  "messages": [
    {
      "_id": "message_id",
      "conversation": "conversation_id",
      "sender": {
        "_id": "user_id",
        "name": "Sender Name",
        "avatar": "url"
      },
      "content": "Hello world",
      "type": "text",
      "status": "sent",
      "createdAt": "2024-01-20T10:05:00.000Z",
      "updatedAt": "2024-01-20T10:05:00.000Z"
    }
  ],
  "pagination": {
    "limit": 50,
    "skip": 0,
    "hasMore": false
  }
}
```

---

### Send Message

**Endpoint:** `POST /api/chat/conversations/[id]/messages`

**Description:** Send a new message to a conversation.

**Request:**
```http
POST /api/chat/conversations/[conversation_id]/messages
Authorization: Bearer <token>
Content-Type: application/json

{
  "content": "Hello there!",
  "type": "text"
}
```

**Request Body:**
- `content`: Message text content
- `type`: "text", "image", "file" (default: "text")
- `replyTo`: ID of message being replied to (optional)
- `attachments`: Array of attachment objects (optional)

**Response (200 Success):**
```json
{
  "message": {
    "_id": "new_message_id",
    "conversation": "conversation_id",
    "sender": "user_id",
    "content": "Hello there!",
    "status": "sent",
    "createdAt": "..."
  }
}
```

---

## 📌 Admission Follow-Up APIs

### Get Application Events

**Endpoint:** `GET /api/me/applications/school/my/[id]/events`

**Description:** Get the timeline of events/notes for a specific application. Available to Parents (own application) and School Staff (school applications).

**Request:**
```http
GET /api/me/applications/school/my/[application_id]/events
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "events": [
    {
      "type": "status_changed",
      "title": "Status Updated",
      "description": "Application status changed from pending to under_review",
      "date": "2024-01-15T10:00:00.000Z",
      "createdBy": {
        "_id": "user_id",
        "name": "Admin Name",
        "role": "school_owner"
      },
      "metadata": {}
    }
  ]
}
```

---

### Add Application Event

**Endpoint:** `POST /api/me/applications/school/my/[id]/events`

**Description:** Add a new event or note to an application. Only available to **School Staff** (Owner, Moderator, Admin).

**Request:**
```http
POST /api/me/applications/school/my/[application_id]/events
Authorization: Bearer <token>
Content-Type: application/json

{
  "type": "note_added",
  "title": "Interview Follow-up",
  "description": "Parent called to confirm attendance.",
  "date": "2024-01-20T14:30:00.000Z"
}
```

**Request Body:**
- `type` (required): Event type. Enum:
   - `note_added`
   - `interview_scheduled`
   - `interview_attended`
   - `interview_missed`
   - `status_changed`
   - `document_requested`
   - `document_received`
   - `parent_contacted`
   - `other`
- `title` (required): Short title for the event
- `description` (optional): Detailed description
- `date` (optional): Event date (defaults to now)
- `metadata` (optional): JSON object with extra data

**Response (200 Success):**
```json
{
  "message": "تم إضافة الحدث بنجاح",
  "event": {
    "type": "note_added",
    "title": "Interview Follow-up",
    "description": "Parent called to confirm attendance.",
    "createdBy": "user_id",
    "date": "2024-01-20T14:30:00.000Z"
  }
}
```

---


---

### Parent: Reply to Event

**Endpoint:** `POST /api/me/applications/[id]/events/reply`

**Description:** Allows a parent to reply to an application event or upload a requested document.

- **:id**: The ID of the Application (not the child ID).

**Request:**
```http
POST /api/me/applications/[application_id]/events/reply
Authorization: Bearer <token>
Content-Type: application/json

{
  "message": "I have attached the birth certificate as requested.",
  "document": {
    "url": "https://storage.googleapis.com/bucket/file123.pdf",
    "label": "birth_certificate",
    "description": "Scanned copy of original"
  }
}
```

**Request Body:**
- `message` (string, optional*): The text comment/reply from the parent.
- `document` (object, optional*): Object containing file details if uploading a file.
   - `url` (string, required): The direct URL of the uploaded file.
   - `label` (string, optional): Type of document (e.g., `birth_certificate`, `national_id`).
   - `description` (string, optional): Optional note about the file.

*\*At least one of `message` or `document` must be provided.*

**Response (200 Success):**
```json
{
  "message": "Reply added successfully",
  "event": {
    "type": "document_received", 
    "title": "Parent Reply (Document Attached)",
    "description": "I have attached...",
    "date": "2024-03-20T10:00:00.000Z",
    "metadata": {
      "hasAttachment": true,
      "attachmentUrl": "https://storage..."
    }
  }
}
```

---

## 👨‍🏫 Teachers Management APIs

All teacher endpoints are scoped to a specific school and require authentication. Access is typically restricted to **School Owners**, **Moderators**, or **Admins**.

### List Teachers

**Endpoint:** `GET /api/schools/my/[id]/teachers`

**Description:** Fetch a paginated list of all teachers belonging to a specific school.

**Request:**
```http
GET /api/schools/my/[school_id]/teachers?limit=20&page=1
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` (optional): Number of teachers per page
- `page` (optional): Page number (default: 1)

**Response (200 Success):**
```json
{
  "teachers": [
    {
      "_id": "teacher_id",
      "name": "Teacher Name",
      "email": "teacher@school.com",
      "role": "teacher",
      "teacher": {
        "employeeId": "EMP001",
        "subjects": [ { "_id": "...", "name": "Math", "grade": { "name": "Grade 10" } } ],
        "gradeLevels": [ { "_id": "...", "name": "Grade 10" } ],
        "class": [ { "_id": "...", "name": "10-A", "grade": { "name": "Grade 10" } } ],
        "hireDate": "2024-01-01T00:00:00Z"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 50,
    "pages": 3,
    "hasMore": true
  }
}
```

---

### Create Teacher

**Endpoint:** `POST /api/schools/my/[id]/teachers`

**Description:** Create a new teacher account and assign them to the specified school.

**Request:**
```http
POST /api/schools/my/[school_id]/teachers
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john.doe@school.com",
  "password": "securePassword123",
  "username": "johndoe",
  "employeeId": "TCH-001",
  "subjects": ["subject_id_1", "subject_id_2"],
  "gradeLevels": ["grade_id_1"],
  "classList": ["class_id_1"],
  "salary": 5000,
  "employmentType": "full_time",
  "hireDate": "2024-01-01",
  "qualifications": ["B.Sc. Education"],
  "experienceYears": 5,
  "isActive": true
}
```

**Required Fields:**
- `name`
- `email`
- `password`

**Optional Fields:**
- `phone`
- `username`
- `employeeId`
- `subjects` (Array of Subject IDs)
- `gradeLevels` (Array of Grade IDs)
- `classList` (Array of Class IDs)
- `hireDate` (Date string)
- `salary` (Number)
- `employmentType` (String: "full_time", "part_time", etc.)
- `qualifications` (Array of Strings)
- `experienceYears` (Number)
- `moodlePassword` (String)

---

### Get Single Teacher Detail

**Endpoint:** `GET /api/schools/my/[id]/teachers/[teacherId]`

**Description:** Retrieve comprehensive details for a specific teacher, including school, subjects, and grade levels.

**Request:**
```http
GET /api/schools/my/[school_id]/teachers/[teacher_id]
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "teacher": {
    "_id": "teacher_id",
    "name": "John Doe",
    "email": "john.doe@school.com",
    "teacher": {
      "school": { "_id": "...", "name": "School Name" },
      "subjects": [...],
      "gradeLevels": [...],
      "timetable": [...]
    }
  }
}
```

---

### Update Teacher

**Endpoint:** `PUT /api/schools/my/[id]/teachers/[teacherId]`

**Description:** Update a teacher's profile, employment details, or account status.

**Request:**
```http
PUT /api/schools/my/[school_id]/teachers/[teacher_id]
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "John Updated",
  "salary": 5500,
  "isActive": true,
  "subjects": ["new_subject_id"],
  "experienceYears": 6
}
```

---

### Update Teacher Timetable

**Endpoint:** `PUT /api/schools/my/[id]/teachers/[teacherId]/timetable`

**Description:** Update the weekly teaching schedule for a specific teacher.

**Request:**
```http
PUT /api/schools/my/[school_id]/teachers/[teacher_id]/timetable
Authorization: Bearer <token>
Content-Type: application/json

{
  "timetable": [
    {
      "day": "Monday",
      "subject": "subject_id",
      "gradeLevel": "grade_id",
      "startTime": "08:00",
      "endTime": "09:00"
    }
  ]
}
```

---

### Delete Teacher

**Endpoint:** `DELETE /api/schools/my/[id]/teachers/[teacherId]`

**Description:** Permanently delete a teacher user from the system.

**Request:**
```http
DELETE /api/schools/my/[school_id]/teachers/[teacher_id]
Authorization: Bearer <token>
```

---

## 👨‍👩‍👧 Parent: Messaging Child's Teachers

This workflow explains how a parent can find the teachers assigned to their child and start a chat conversation with them.

### Step 1: Get Child & Class Info
First, retrieve your child's profile to get their `schoolId` and `class` (Classroom) ID.

**Endpoint:** `GET /api/children/get-related`

**Snippet:**
```json
{
  "children": [
    {
      "_id": "child_id",
      "fullName": "Child Name",
      "schoolId": "school_id",
      "class": {
        "_id": "class_id",
        "name": "1-A"
      }
    }
  ]
}
```

---

### Step 2: Get Class Teachers
Use the `schoolId` and `class_id` from Step 1 to fetch the list of teachers assigned to your child's specific classroom.

**Endpoint:** `GET /api/schools/my/[schoolId]/classes/[classId]`

**Response (200 OK):**
```json
{
  "class": { ... },
  "teachers": [
    {
      "_id": "teacher_user_id",
      "name": "Teacher Name",
      "avatar": "...",
      "role": "teacher"
    }
  ]
}
```

---

### Step 3: Start a Conversation
Once you have the `teacher_user_id`, create or retrieve a direct chat conversation with them.

**Endpoint:** `POST /api/chat/conversations`
**Body:**
```json
{
  "participants": ["teacher_user_id"],
  "type": "direct"
}
```

**Response:**
```json
{
  "conversation": {
    "_id": "conv_id",
    "type": "direct"
  }
}
```

---

### Step 4: Send the Message
Use the `conv_id` from Step 3 to send your message.

**Endpoint:** `POST /api/chat/conversations/[conv_id]/messages`
**Body:**
```json
{
  "content": "Hello Teacher, I wanted to ask about my child's progress.",
  "type": "text"
}
```

---


---

## 14. Store & E-commerce APIs

This section covers the Store APIs including Product Management, Cart (DB-Synced), and Order Checkout.

### Base URL
`/api/store`

### Authentication
All Cart and Checkout APIs require a Bearer Token in the `Authorization` header.
`Authorization: Bearer <token>`

### List Products
- **URL:** `/api/store/products?category=<id>&search=query&featured=true`
- **Method:** `GET`

### Get Product Details
- **URL:** `/api/store/products/[id]`
- **Method:** `GET`

### Cart Management (DB-Synced)
The cart is now stored in the database, allowing synchronization between Web and Mobile apps.

#### Get Cart
Retrieves the current user's cart items with full product details and calculated prices.

- **URL:** `/api/store/cart`
- **Method:** `GET`
- **Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "_id": "cart_item_id",
        "productId": "product_id",
        "product": { "title_en": "Item", "price": 100, "images": [...] },
        "quantity": 2,
        "selections": [{ "name": "Size", "value": "XL" }],
        "price": 90,
        "subtotal": 180
      }
    ],
    "subtotal": 180,
    "total": 180,
    "itemCount": 2
  }
}
```

#### Add/Update Item in Cart
Adds a new item to the cart or increases quantity if identical item exists.

- **URL:** `/api/store/cart`
- **Method:** `POST`
- **Body:**
```json
{
  "productId": "string",
  "quantity": 1,
  "selections": [
    { "name": "Color", "value": "Red" }
  ]
}
```

#### Update Item Quantity
Corrects the quantity of a specific item in the cart.

- **URL:** `/api/store/cart`
- **Method:** `PUT`
- **Body:**
```json
{
  "cartItemId": "string", 
  "quantity": 5
}
```

#### Remove Item / Clear Cart
- **URL:** `/api/store/cart?cartItemId=<id>` (Delete single)
- **URL:** `/api/store/cart?clear=true` (Clear all)
- **Method:** `DELETE`

### Orders & Checkout

#### Create Order (Checkout)
Creates an order. If `items` are not provided, it automatically checks out the user's current DB cart.

- **URL:** `/api/store/orders`
- **Method:** `POST`
- **Body:**
```json
{
  "paymentMethod": "wallet", 
  "deliveryMethod": "pickup",
  "shippingAddress": {
     "address": "123 Street",
     "city": "Cairo",
     "phone": "0123456789"
  },
  "notes": "Please deliver after 5 PM",
  "school": "optional_school_id"
}
```
*Note: If `paymentMethod` is `wallet`, the balance is deducted automatically.*

#### Get Order History
- **URL:** `/api/store/orders?page=1&limit=10&status=pending`
- **Method:** `GET`

---


---

## 15. Notifications APIs

### List Notifications

**Endpoint:** `GET /api/notifications`

**Description:** Fetch notifications for the authenticated user (Parent or Teacher). Returns a list of notifications and the count of unread notifications.

**Request:**
```http
GET /api/notifications?limit=20
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` (optional): Number of notifications to return (default: 20)

**Response (200 OK):**
```json
{
  "notifications": [
    {
      "_id": "notification_id",
      "recipient": "user_id",
      "type": "application_status_update",
      "title": "Application Status Changed",
      "message": "Your application for John has been approved.",
      "status": "unread",
      "createdAt": "2024-03-20T10:00:00.000Z",
      "school": { "name": "School Name", "logoUrl": "..." },
      "student": { "name": "John" },
      "application": { "status": "approved" }
    }
  ],
  "unreadCount": 5
}
```

### Mark All Read

**Endpoint:** `POST /api/notifications/read-all`

**Description:** Mark all notifications as read for a specific user.

**Request:**
```http
POST /api/notifications/read-all?userId=user_id
Authorization: Bearer <token>
```

**Query Parameters:**
- `userId` (required): The ID of the user whose notifications should be marked as read.

**Response (200 OK):**
```json
{
  "message": "All notifications marked as read",
  "modifiedCount": 5
}
```

### Create Notification (System)

**Endpoint:** `POST /api/notifications`

**Description:** Create a new notification (typically used by internal system processes).

**Request:**
```http
POST /api/notifications
Authorization: Bearer <token>
Content-Type: application/json

{
  "recipient": "user_id",
  "type": "custom",
  "title": "Welcome!",
  "message": "Welcome to our platform.",
  "school": "school_id"
}
```

---

_Last updated: February 2026_
# Derasy Platform API Documentation

> **📖 Documentation Files:**
> - **[API-README.md](./API-README.md)** - Quick start guide and common use cases
> - **[API-WORKFLOWS.md](./API-WORKFLOWS.md)** - Step-by-step workflows and code examples
> - **This file** - Complete API reference

---

## 📚 Table of Contents
1. [Quick Start Guide](#quick-start-guide)
2. [Authentication](#authentication)
3. [User & Account Management](#user--account-management-apis)
   - [Check User Existence](#check-user-existence)
4. [Children Management APIs](#children-management-apis)
   - [Add Child with Birth Certificate Extraction](#add-child-with-birth-certificate-extraction)
   - [Two-Step Document Upload Flow](#two-step-document-upload-flow)
   - [OTP Verification Flow for Existing Children](#otp-verification-flow-for-existing-children)
   - [Non-Egyptian Child Requests Flow](#non-egyptian-child-requests-flow)
   - [Admin: Non-Egyptian Child Requests Management](#admin-non-egyptian-child-requests-management)
   - [Get Children](#get-children)
   - [Update Child](#update-child)
   - [Upload Documents](#upload-documents)
5. [Admission Flow APIs](#admission-flow-apis)
   - [Get AI School Suggestions](#get-ai-school-suggestions)
   - [Submit Admission Application](#submit-admission-application)
   - [Reorder Applications](#reorder-applications)
   - [Get Parent's Applications](#get-parents-applications)
   - [Get School Applications](#get-school-applications)
   - [Get Single Application Detail](#get-single-application-detail)
   - [Set Interview Date](#set-interview-date)
   - [Custom Admission Forms APIs](#custom-admission-forms-apis)
6. [School Management & Sales APIs](#school-management--sales-apis)
   - [Sales: Register New School (Onboarding)](#sales-register-new-school-onboarding)
   - [School: Get Quick Statistics](#school-get-quick-statistics)
   - [School: Check User Access Permissions](#school-check-user-access-permissions)
7. [Common Workflows](#common-workflows)
8. [Error Handling](#error-handling)
9. [Wallet Management APIs](#wallet-management-apis)
10. [Reports & Analytics APIs](#reports--analytics-apis)
   - [School Comprehensive AI Report](#school-comprehensive-ai-report)
   - [List Custom Report Templates](#list-custom-report-templates)
   - [Manage Report Templates](#manage-report-templates)
11. [Chat & Messaging APIs](#chat--messaging-apis)
   - [List Conversations](#list-conversations)
   - [Create Conversation](#create-conversation)
   - [Get Messages](#get-messages)
   - [Send Message](#send-message)
12. [Admission Follow-Up APIs](#admission-follow-up-apis)
   - [Get Application Events](#get-application-events)
   - [Add Application Event](#add-application-event)
   - [Parent: Reply to Event](#parent-reply-to-event)
13. [Teachers Management APIs](#teachers-management-apis)
   - [List Teachers](#list-teachers)
   - [Create Teacher](#create-teacher)
   - [Get Single Teacher](#get-single-teacher-detail)
   - [Update Teacher](#update-teacher)
   - [Update Teacher Timetable](#update-teacher-timetable)
   - [Delete Teacher](#delete-teacher)
14. [Store & E-commerce APIs](#store--e-commerce-apis)
   - [Cart Management](#cart-management)
   - [Orders & Checkout](#orders--checkout)
   - [Products](#products)

---

15. [Notifications APIs](#notifications-apis)
   - [List Notifications](#list-notifications)
   - [Mark All Read](#mark-all-read)
   - [Create Notification (System)](#create-notification-system)

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
  "user": {
    "_id": "user_id",
    "role": "parent",
    "email": "user@example.com",
    "username": "user123"
  }
}
```

### Validate Token
```http
GET /api/me
Authorization: Bearer <token>
```
**Response:**
```json
{
  "user": { ... }
}
```

---

## 👤 User & Account Management APIs

### Check User Existence

**Endpoint:** `POST /api/users/check`

**Description:** Check if a user already exists in the system by email or phone number. Useful for validation before creating new accounts during onboarding.

**Request:**
```http
POST /api/users/check
Content-Type: application/json

{
  "email": "user@example.com",
  "phone": "01234567890"
}
```

**Response (200 Success - Found):**
```json
{
  "exists": true,
  "message": "User already exists: user@example.com"
}
```

**Response (200 Success - Not Found):**
```json
{
  "exists": false
}
```

**Notes:**
- ✅ Checks against both `email` and `phone` fields.
- ✅ Returns `exists: true` if either matches.

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
- ✅ Handles Arabic written years (e.g., "عام الفان و ثلاثه عشر" = 2013)
- ✅ Calculates age in coming October automatically
- ✅ Combines child name + father name for full Arabic name
- ✅ Validates National ID uniqueness before extraction completes
- ✅ **New:** Supports passport extraction for non-Egyptian children.

---

### Extract National ID Data (Egyptian)

**Endpoint:** `POST /api/children/extract-national-id`

**Description:** Extracts data from Egyptian National ID card (Front and/or Back) using Google Gemini AI. Both front and back images can be provided for better accuracy.

**Request:**
```http
POST /api/children/extract-national-id
Authorization: Bearer <token>
Content-Type: multipart/form-data

Form Data:
- nationalIdFront: [front_image_file] (optional)
- nationalIdBack: [back_image_file] (optional)
- nationalId: [image_file] (optional, backward compatibility, treated as front)
```

**Response (200 Success):**
```json
{
  "success": true,
  "extractedData": {
    "nationalId": "29001011234567",
    "fullName": "Name in English",
    "arabicFullName": "الاسم بالعربي",
    "birthDate": "1990-01-01",
    "gender": "male",
    "religion": "Muslim",
    "address": "123 Street Name, City",
    "birthPlace": "Cairo",
    "nationalIdImages": {
       "front": {
         "url": "https://ik.imagekit.io/...",
         "publicId": "...",
         "uploadedAt": "2024-01-01T10:00:00.000Z"
       },
       "back": {
         "url": "https://ik.imagekit.io/...",
         "publicId": "...",
         "uploadedAt": "2024-01-01T10:00:00.000Z"
       }
    },
    "nationalIdImage": { 
      "url": "https://ik.imagekit.io/..." 
    }
  },
  "extractedText": "Raw extracted text...",
  "documentType": "national_id"
}
```

**Response (503 Service Unavailable):**
```json
{
  "message": "OCR extraction failed. Please enter data manually.",
  "error": "Error details",
  "canContinue": true
}
```

**Notes:**
- ✅ Supports both front and back images
- ✅ Combines text info from both images
- ✅ Extracts names (Arabic/English), Address, ID number, Birth date, etc.
- ✅ Handles rate limits gracefully

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
- `birthCertificate` (file or object with `data`/`url`)
- `parentPassport` (file or object, for non-Egyptian)
- `childPassport` (file or object, for non-Egyptian)
- `parentNationalIdCard` (file or object, for Egyptian)

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
      "schoolId": {
        "_id": "school_id", 
        "name": "School Name",
        "nameAr": "اسم المدرسة",
        "logo": {
          "url": "..."
        }
      },
      "grade": {
        "_id": "grade_id",
        "name": "Grade 1",
        "nameAr": "الاول الابتدائي"
      }
    }
  ],
  "count": 1
}
```

### Note on Performance
The `GET /api/children/get-related` endpoint is optimized to return only essential data for the list view. It specifically populates `schoolId` and `grade` but omits heavy nested relations like `parent.user`, `sections`, etc., to ensure fast loading times.

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

## 📚 Admission Flow APIs

### Get AI School Suggestions

**Endpoint:** `POST /api/schools/suggest-three`

**Description:** Uses Google Gemini AI to analyze a child's profile against a list of schools and user preferences to suggest the top 3 most suitable schools.

**Request:**
```http
POST /api/schools/suggest-three
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "child": {
    "_id": "child_id",
    "fullName": "Student Name",
    "gender": "male",
    "ageInOctober": 68
    // ... complete child object
  },
  "schools": [
    // Array of school objects to analyze
    {
      "_id": "school_id_1",
      "name": "School A",
      "admissionFee": { "amount": 50000 },
      "type": "National"
    },
    {
      "_id": "school_id_2",
      "name": "School B",
      "admissionFee": { "amount": 80000 },
      "type": "International"
    }
  ],
  "preferences": {
    "minFee": 20000,
    "maxFee": 60000,
    "busFeeMax": 15000,
    "zone": "Nasr City",
    "type": "National",
    "coed": "mixed",
    "language": "English"
  }
}
```

**Preferences Object Details:**
- `minFee` (Number, optional): Minimum tuition fee preference.
- `maxFee` (Number, optional): Maximum tuition fee preference.
- `busFeeMax` (Number, optional): Maximum bus subscription fee.
- `zone` (String, optional): Filter by school zone/area.
- `type` (String, optional): School type (e.g., "National", "International", "American").
- `coed` (String, optional): "mixed" for Co-ed, "single" for Segregated.
- `language` (String, optional): Primary language preference.

**Response (200 Success):**
```json
{
  "message": "تم إنشاء الترشيحات بنجاح",
  "markdown": "## تحليل الذكاء الاصطناعي\n\nبناءً على ملف الطالب...\n* **مدرسة المستقبل**: لأنها تناسب الميزانية...",
  "html": "<h2>تحليل الذكاء الاصطناعي</h2>...",
  "suggestedIds": ["school_id_1", "school_id_5", "school_id_8"]
}
```

**Response (429 Too Many Requests):**
```json
{
  "message": "عذراً، المساعد الذكي مشغول جداً حالياً..."
}
```

**Notes:**
- ✅ Returns analysis in Egyptian Arabic (Markdown & HTML).
- ✅ Prioritizes user hard constraints (Fees, Zone) in the AI prompt.
- ✅ Returns raw list of suggested School IDs for UI highlighting.

---

### Submit Admission Application

**Endpoint:** `POST /api/admission/apply`

**Description:** Submit an admission application for a child to one or more schools. The system will create a "pending" application for the first school and "draft" applications for others. Deducts the *highest* admission fee among the selected schools from the parent's wallet.

**Request:**
```http
POST /api/admission/apply
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
      "name": "Primary Choice School",
      "admissionFee": { "amount": 500 }
    },
    {
      "_id": "school_id_2",
      "name": "Secondary Choice School",
      "admissionFee": { "amount": 300 }
    }
  ]
}
```

**Required Fields:**
- `childId` - The ID of the child applying
- `selectedSchools` - Array of school objects. The first one will be the primary application.

**Response (200 Success):**
```json
{
  "message": "✅ تم إنشاء الطلبات بنجاح",
  "applications": [
    {
      "_id": "application_id_1",
      "status": "pending",
      "priority": 0,
      "payment": { "isPaid": true, "amount": 500 }
      // ...
    },
    {
      "_id": "application_id_2",
      "status": "draft",
      "priority": 1,
      "payment": { "isPaid": true, "amount": 0 }
      // ...
    }
  ]
}
```

**Response (400 Bad Request - Insufficient Balance):**
```json
{
  "message": "رصيدك غير كافٍ. تحتاج إلى 500 جنيه على الأقل.",
  "details": {
    "currentBalance": 200,
    "requiredAmount": 500,
    "shortfall": 300
  }
}
```

---

### Reorder Applications

**Endpoint:** `PUT /api/applications/reorder`

**Description:** Reorder the priority of a parent's applications. Useful for changing which school is the primary choice.

**Request:**
```http
PUT /api/applications/reorder
Authorization: Bearer <token>
Content-Type: application/json

{
  "orderedIds": ["app_id_2", "app_id_1", "app_id_3"]
}
```

**Response (200 Success):**
```json
{
  "message": "Order updated successfully"
}
```

---

### Get Parent's Applications

**Endpoint:** `GET /api/me/applications`

**Description:** Get all admission applications submitted by the authenticated parent.

**Request:**
```http
GET /api/me/applications
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "applications": [
    {
      "_id": "application_id",
      "child": { ... },
      "school": { ... },
      "status": "pending",
      "priority": 0,
      "submittedAt": "2025-01-15T10:00:00.000Z"
    }
  ]
}
```

---

### Get School Applications

**Endpoint:** `GET /api/schools/my/[id]/admission-forms`

**Description:** Get all admission applications for a specific school (school owner/moderator/admin only). Returns only non-draft applications.

**Request:**
```http
GET /api/schools/my/school_id/admission-forms
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "applications": [ ... ],
  "school": { ... },
  "totalApplications": 15,
  "byStatus": {
    "pending": 5,
    "under_review": 3,
    "accepted": 5,
    "rejected": 2
  }
}
```

---

### Get Single Application Detail

**Endpoint:** `GET /api/me/applications/school/my/[applicationId]`

**Description:** Get detailed information about a specific application (school owner/moderator/admin only).

**Request:**
```http
GET /api/me/applications/school/my/application_id
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "_id": "application_id",
  "parent": { ... },
  "child": { ... },
  "school": { ... },
  "status": "under_review",
  "interview": { ... },
  "events": [ ... ]
}
```

---

### Set Interview Date

**Endpoint:** `PUT /api/me/applications/school/my/[applicationId]`

**Description:** Set or update the interview date for an application. Automatically updates status to `under_review` and sends email notification to parent.

**Request:**
```http
PUT /api/me/applications/school/my/application_id
Authorization: Bearer <token>
Content-Type: application/json

{
  "interviewDate": "2025-02-20",
  "interviewTime": "11:30 AM",
  "location": "Main Office",
  "notes": "Bring original birth certificate"
}
```

**Response (200 Success):**
```json
{
  "message": "تم تحديد موعد المقابلة بنجاح",
  "application": { ... }
}
```

---

### Custom Admission Forms APIs

These APIs manage the school's own customized admission forms (builder-based).

#### List School Custom Forms
**Endpoint:** `GET /api/schools/my/[id]/admission-forms/templates`
*(Note: Route may vary, please verify school-side form listing)*

#### Get Custom Form Details
**Endpoint:** `GET /api/schools/my/[id]/admission-forms/[formId]`

#### Submit Custom Form
**Endpoint:** `POST /api/schools/my/[id]/admission-forms/[formId]/submissions`

#### View Form Submissions
**Endpoint:** `GET /api/schools/my/[id]/admission-forms/[formId]/submissions`

#### Manage Submission Status
**Endpoint:** `PUT /api/schools/my/[id]/admission-forms/[formId]/submissions/[submissionId]`
**Body:** `{ "status": "approved", "notes": "..." }`

**Response (200 Success):**
```json
{
  "applications": [
    {
      "_id": "application_id",
      "parent": {
        "_id": "parent_user_id",
        "name": "Parent Name",
        "email": "parent@example.com",
        "phone": "01234567890"
      },
      "child": {
        "_id": "child_id",
        "fullName": "Child Name",
        "arabicFullName": "اسم الطفل",
        "birthDate": "2013-06-03T00:00:00.000Z",
        "currentSchool": "Previous School",
        "desiredGrade": "Grade 5"
      },
      "status": "pending",
      "applicationType": "transfer",
      "payment": {
        "isPaid": true,
        "amount": 500
      },
      "submittedAt": "2025-01-15T10:00:00.000Z"
    }
  ],
  "count": 1
}
```

**Response (403 Forbidden):**
```json
{
  "message": "Access denied: You do not have permission to view applications for this school"
}
```

**Notes:**
- ✅ Only school owners, moderators, and admins can access
- ✅ Supports filtering by status
- ✅ Returns parent and child information

---

### Get Single Application

**Endpoint:** `GET /api/me/applications/school/my/[id]`

**Description:** Get detailed information about a specific application (school admin or parent).

**Request:**
```http
GET /api/me/applications/school/my/application_id
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "_id": "application_id",
  "parent": {
    "_id": "parent_user_id",
    "name": "Parent Name",
    "email": "parent@example.com",
    "phone": "01234567890"
  },
  "child": {
    "_id": "child_id",
    "fullName": "Child Name",
    "arabicFullName": "اسم الطفل",
    "birthDate": "2013-06-03T00:00:00.000Z",
    "gender": "male",
    "nationalId": "31303170105673",
    "currentSchool": "Previous School",
    "desiredGrade": "Grade 5",
    "documents": [
      {
        "url": "https://imagekit.io/...",
        "label": "birth_certificate",
        "source": "uploaded"
      }
    ]
  },
  "school": {
    "_id": "school_id",
    "name": "School Name",
    "nameAr": "اسم المدرسة",
    "type": "private",
    "admissionFee": {
      "amount": 500
    }
  },
  "status": "under_review",
  "applicationType": "new_student",
  "interview": {
    "date": "2025-02-20T00:00:00.000Z",
    "time": "11:30 AM",
    "location": "Main Office - First Floor",
    "notes": "Please bring all required documents"
  },
  "preferredInterviewSlots": [
    {
      "date": "2025-02-15T00:00:00.000Z",
      "timeRange": {
        "from": "10:00 AM",
        "to": "12:00 PM"
      }
    }
  ],
  "payment": {
    "isPaid": true,
    "amount": 500,
    "paidAt": "2025-01-15T10:00:00.000Z",
    "method": "wallet"
  },
  "events": [
    {
      "_id": "event_id",
      "type": "interview_scheduled",
      "title": "تم تحديد موعد المقابلة",
      "description": "تم تحديد موعد المقابلة في 20 فبراير 2025 الساعة 11:30 AM",
      "date": "2025-01-16T10:00:00.000Z",
      "createdBy": {
        "_id": "admin_user_id",
        "name": "Admin Name"
      }
    }
  ],
  "submittedAt": "2025-01-15T10:00:00.000Z",
  "updatedAt": "2025-01-16T10:00:00.000Z"
}
```

**Response (403 Forbidden):**
```json
{
  "message": "Access denied: You do not have permission to view this application"
}
```

**Notes:**
- ✅ School admins can view applications for their schools
- ✅ Parents can view their own applications
- ✅ Includes full child and parent information
- ✅ Includes interview details if scheduled
- ✅ Includes events/notes timeline

---

### Set Interview Date

**Endpoint:** `PUT /api/me/applications/school/my/[id]`

**Description:** Set interview date for an application (school admin only). Automatically creates an event and sends email notification to parent.

**Request:**
```http
PUT /api/me/applications/school/my/application_id
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "date": "2025-02-20",
  "time": "11:30 AM",
  "location": "Main Office - First Floor",
  "notes": "Please bring all required documents"
}
```

**Alternative Field Names (also supported):**
```json
{
  "interviewDate": "2025-02-20",
  "interviewTime": "11:30 AM",
  "location": "Main Office - First Floor",
  "notes": "Please bring all required documents"
}
```

**Required Fields:**
- `date` or `interviewDate` - Interview date in YYYY-MM-DD format
- `time` or `interviewTime` - Interview time (e.g., "11:30 AM")

**Optional Fields:**
- `location` - Interview location
- `notes` - Additional notes for parent

**Response (200 Success):**
```json
{
  "message": "تم تحديد موعد المقابلة بنجاح",
  "application": {
    "_id": "application_id",
    "interview": {
      "date": "2025-02-20T00:00:00.000Z",
      "time": "11:30 AM",
      "location": "Main Office - First Floor",
      "notes": "Please bring all required documents"
    },
    "status": "under_review",
    "events": [
      {
        "type": "interview_scheduled",
        "title": "تم تحديد موعد المقابلة",
        "description": "تم تحديد موعد المقابلة في 20 فبراير 2025 الساعة 11:30 AM في Main Office - First Floor",
        "date": "2025-01-16T10:00:00.000Z",
        "createdBy": "admin_user_id"
      }
    ]
  }
}
```

**Response (400 Bad Request):**
```json
{
  "message": "يرجى إدخال تاريخ ووقت المقابلة"
}
```

**Notes:**
- ✅ Automatically changes application status to `under_review`
- ✅ Creates `interview_scheduled` event automatically
- ✅ Sends email notification to parent with interview details
- ✅ Email includes formatted date, time, location, and notes

---

### Application Events/Notes

**Endpoint:** `POST /api/me/applications/school/my/[id]/events`

**Description:** Add an event/note to an application's follow-up timeline (school admin only).

**Request:**
```http
POST /api/me/applications/school/my/application_id/events
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "type": "note_added",
  "title": "تم التواصل مع ولي الأمر",
  "description": "تم التواصل مع ولي الأمر عبر الهاتف وتم التأكيد على الحضور",
  "date": "2025-01-17",
  "metadata": {
    "contactMethod": "phone",
    "phoneNumber": "01234567890"
  }
}
```

**Event Types:**
- `note_added` - General note
- `interview_scheduled` - Interview date set (usually auto-created)
- `interview_attended` - Parent attended interview
- `interview_missed` - Parent missed interview
- `status_changed` - Application status changed (usually auto-created)
- `parent_contacted` - Contacted parent
- `document_requested` - Requested document from parent
- `document_received` - Received document from parent
- `other` - Other event type

**Required Fields:**
- `type` - Event type (must be one of the above)
- `title` - Event title

**Optional Fields:**
- `description` - Detailed description
- `date` - Event date (defaults to current date)
- `metadata` - Additional metadata object

**Response (200 Success):**
```json
{
  "message": "تم إضافة الحدث بنجاح",
  "event": {
    "_id": "event_id",
    "type": "note_added",
    "title": "تم التواصل مع ولي الأمر",
    "description": "تم التواصل مع ولي الأمر عبر الهاتف وتم التأكيد على الحضور",
    "date": "2025-01-17T00:00:00.000Z",
    "createdBy": {
      "_id": "admin_user_id",
      "name": "Admin Name"
    },
    "metadata": {
      "contactMethod": "phone",
      "phoneNumber": "01234567890"
    }
  },
  "application": {
    "_id": "application_id",
    "events": [...]
  }
}
```

**Response (400 Bad Request):**
```json
{
  "message": "يرجى إدخال نوع الحدث والعنوان"
}
```

---

**Endpoint:** `GET /api/me/applications/school/my/[id]/events`

**Description:** Get all events/notes for an application (school admin or parent).

**Request:**
```http
GET /api/me/applications/school/my/application_id/events
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "events": [
    {
      "_id": "event_id",
      "type": "interview_scheduled",
      "title": "تم تحديد موعد المقابلة",
      "description": "تم تحديد موعد المقابلة في 20 فبراير 2025 الساعة 11:30 AM",
      "date": "2025-01-16T10:00:00.000Z",
      "createdBy": {
        "_id": "admin_user_id",
        "name": "Admin Name",
        "email": "admin@example.com",
        "role": "school_owner"
      },
      "metadata": {
        "interviewDate": "2025-02-20T00:00:00.000Z",
        "interviewTime": "11:30 AM",
        "location": "Main Office"
      }
    },
    {
      "_id": "event_id_2",
      "type": "interview_attended",
      "title": "تم حضور المقابلة",
      "description": "تم حضور ولي الأمر والطفل في الموعد المحدد للمقابلة",
      "date": "2025-02-20T11:30:00.000Z",
      "createdBy": {
        "_id": "admin_user_id",
        "name": "Admin Name"
      }
    }
  ]
}
```

**Notes:**
- ✅ Events are sorted by date (newest first)
- ✅ Each event includes creator information
- ✅ Parents can view events for their applications
- ✅ School admins can view and add events

---

### Update Application Status

**Endpoint:** `PUT /api/me/applications/school/my/[id]/status`

**Description:** Update application status (school admin only). Automatically creates a status change event.

**Request:**
```http
PUT /api/me/applications/school/my/application_id/status
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "status": "accepted",
  "note": "Application accepted after successful interview"
}
```

**Required Fields:**
- `status` - New status: "pending", "under_review", "recommended", "accepted", "rejected", or "draft"

**Optional Fields:**
- `note` - Additional note for the status change

**Response (200 Success):**
```json
{
  "message": "تم تحديث الحالة بنجاح",
  "application": {
    "_id": "application_id",
    "status": "accepted",
    "events": [
      {
        "type": "status_changed",
        "title": "تغيير الحالة من قيد المراجعة إلى تم القبول",
        "description": "Application accepted after successful interview",
        "date": "2025-01-18T10:00:00.000Z",
        "createdBy": "admin_user_id",
        "metadata": {
          "oldStatus": "under_review",
          "newStatus": "accepted"
        }
      }
    ]
  }
}
```

**Response (400 Bad Request):**
```json
{
  "message": "حالة غير صالحة"
}
```

**Response (403 Forbidden):**
```json
{
  "message": "Access denied: You do not have permission to modify this application"
}
```

**Notes:**
- ✅ Automatically creates `status_changed` event
- ✅ Event includes old and new status in metadata
- ✅ Only school owners, moderators, and admins can update status
- ✅ Status change is logged in events timeline

---

## 🏫 School Management & Sales APIs

### Sales: Register New School (Onboarding)

**Endpoint:** `POST /api/sales/onboarding`

**Description:** Performs a complete onboarding of a new school, including creating or updating the School Owner and Moderator accounts, and initializing the school record.

**Request:**
```http
POST /api/sales/onboarding
Authorization: Bearer <sales_token>
Content-Type: application/json

{
  "schoolData": {
    "name": "School Name",
    "type": "General",
    "location": { ... },
    "feesDetails": { ... }
  },
  "ownerData": {
    "name": "Owner Name",
    "email": "owner@example.com",
    "phone": "01012345678",
    "password": "securepassword"
  },
  "moderatorData": {
    "name": "Moderator Name",
    "email": "mod@example.com",
    "phone": "01087654321",
    "password": "securepassword"
  },
  "configData": {
    "approved": true,
    "showInSearch": true
  }
}
```

**Response (201 Created):**
```json
{
  "message": "School created successfully",
  "schoolId": "new_school_id"
}
```

---

### School: Get Quick Statistics

**Endpoint:** `GET /api/schools/my/[id]/quick-stats`

**Description:** Returns a summary of key metrics for a school. Requires Owner, Moderator, or Admin permissions.

**Request:**
```http
GET /api/schools/my/school_id/quick-stats
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "stats": {
    "activeStudents": 150,
    "applications": 45,
    "tasks": 12
  }
}
```

**Notes:**
- **activeStudents**: Total children enrolled in the school.
- **applications**: Total admission applications (excluding drafts).
- **tasks**: Applications pending review (status: `pending` or `under_review`).

---

### School: Get Quick Statistics

**Endpoint:** `GET /api/schools/my/[id]/quick-stats`

**Description:** Get key metrics for the school moderator dashboard, including student count, total applications, and pending tasks.

**Request:**
```http
GET /api/schools/my/school_id/quick-stats
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "stats": {
    "activeStudents": 150,
    "applications": 45,
    "tasks": 12
  }
}
```

---

### School: Check User Access Permissions

**Endpoint:** `GET /api/schools/my/[id]/check-access`

**Description:** Verifies if the authenticated user has permission to manage the specified school and returns their role-based permissions.

**Request:**
```http
GET /api/schools/my/school_id/check-access
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "authorized": true,
  "isOwner": false,
  "isModerator": true,
  "isAdmin": false,
  "isSales": false,
  "school": {
    "_id": "school_id",
    "name": "School Name",
    "nameAr": "اسم المدرسة"
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

### Workflow 4: Submit Admission Application

**Use Case:** Parent wants to apply for their child to one or more schools.

**Steps:**
1. **Submit Application**
   ```javascript
   const response = await fetch('/api/admission/apply', {
     method: 'POST',
     headers: {
       'Authorization': `Bearer ${token}`,
       'Content-Type': 'application/json'
     },
     body: JSON.stringify({
       childId: 'child_id',
       selectedSchools: [
         { _id: 'school_id_1', name: 'School 1', admissionFee: { amount: 500 } },
         { _id: 'school_id_2', name: 'School 2', admissionFee: { amount: 300 } }
       ]
     })
   });
   
   const { applications } = await response.json();
   ```

2. **Check Application Status**
   ```javascript
   const response = await fetch('/api/me/applications', {
     headers: { 'Authorization': `Bearer ${token}` }
   });
   
   const { applications } = await response.json();
   ```

**✅ Benefits:**
- Automatic highest fee wallet deduction
- First school gets "pending" status, others "draft"
- Email notification to primary school
- Full application tracking

---

### Workflow 5: School Admin - Review Application

**Use Case:** School admin wants to review and manage an application.

**Steps:**
1. **Get Application Details**
   ```javascript
   const response = await fetch(`/api/me/applications/school/my/${applicationId}`, {
     headers: { 'Authorization': `Bearer ${token}` }
   });
   
   const application = await response.json();
   ```

2. **Set Interview Date**
   ```javascript
   const response = await fetch(`/api/me/applications/school/my/${applicationId}`, {
     method: 'PUT',
     headers: {
       'Authorization': `Bearer ${token}`,
       'Content-Type': 'application/json'
     },
     body: JSON.stringify({
       interviewDate: '2025-02-20',
       interviewTime: '11:30 AM',
       location: 'Main Office',
       notes: 'Bring required documents'
     })
   });
   ```

3. **Add Event/Note**
   ```javascript
   const response = await fetch(`/api/me/applications/school/my/${applicationId}/events`, {
     method: 'POST',
     headers: {
       'Authorization': `Bearer ${token}`,
       'Content-Type': 'application/json'
     },
     body: JSON.stringify({
       type: 'interview_attended',
       title: 'تم حضور المقابلة',
       description: 'تم حضور ولي الأمر والطفل في الموعد المحدد'
     })
   });
   ```

4. **Update Status**
   ```javascript
   const response = await fetch(`/api/me/applications/school/my/${applicationId}/status`, {
     method: 'PUT',
     headers: {
       'Authorization': `Bearer ${token}`,
       'Content-Type': 'application/json'
     },
     body: JSON.stringify({
       status: 'accepted',
       note: 'Application accepted after successful interview'
     })
   });
   ```

**✅ Benefits:**
- Complete application management
- Event tracking for follow-up
- Automatic email notifications
- Status change logging

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
| `/api/users/check` | POST | Check if user exists (email/phone) |
| `/api/sales/onboarding` | POST | New school registration (Sales) |
| `/api/schools/my/[id]/quick-stats` | GET | School summary metrics |
| `/api/schools/my/[id]/check-access` | GET | Verify permissions for a school |
| `/api/children/extract-birth-certificate` | POST | Extract data from documents |
| `/api/children` | POST | Add new child |
| `/api/children/get-related` | GET | Get all children |
| `/api/children/get-related/[id]` | GET | Get single child |
| `/api/children/get-related/[id]` | PUT | Update child |
| `/api/children/get-related/[id]/upload` | PUT | Upload documents |
| `/api/admission/apply` | POST | Submit admission application |
| `/api/applications/reorder` | PUT | Reorder parent applications |
| `/api/me/applications` | GET | Get parent's applications |
| `/api/schools/my/[id]/admission-forms` | GET | Get school applications |
| `/api/me/applications/school/my/[id]` | GET | Get single application |
| `/api/me/applications/school/my/[id]` | PUT | Set interview date |
| `/api/me/applications/school/my/[id]/events` | POST | Add event/note |
| `/api/me/applications/school/my/[id]/events` | GET | Get application events |
| `/api/me/applications/school/my/[id]/status` | PUT | Update application status |
| `/api/bank-accounts` | GET | Active bank accounts |
| `/api/me/wallet/deposit` | POST | Deposit funds |
| `/api/me/wallet/withdraw` | POST | Withdraw funds |

---

## 💰 Wallet Management APIs

### Get Active Bank Accounts

**Endpoint:** `GET /api/bank-accounts`

**Description:** Get list of active bank accounts for manual transfers.

**Request:**
```http
GET /api/bank-accounts
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "accounts": [
    {
      "_id": "bank_id",
      "bankName": "National Bank of Egypt",
      "accountHolder": "Derasy Inc.",
      "accountNumber": "1234567890",
      "iban": "EG1234567890...",
      "branch": "Main Branch",
      "instructions": "Please include your email in transfer notes",
      "isActive": true
    }
  ]
}
```

---

### Deposit Funds (Bank Transfer)

**Endpoint:** `POST /api/me/wallet/deposit`

**Description:** Requests a deposit via manual bank transfer. The transaction is created with `pending` status until admin approval.

**Request:**
```http
POST /api/me/wallet/deposit
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "amount": 1000,
  "method": "bank_transfer",
  "bankAccountId": "bank_id_from_get_accounts",
  "attachment": {
    "url": "https://imagekit.io/...",
    "publicId": "receipt_image_id"
  }
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Deposit request submitted successfully",
  "transaction": {
    "user": "user_id",
    "type": "deposit",
    "amount": 1000,
    "method": "bank_transfer",
    "status": "pending",
    "description": "تحويل بنكي - في انتظار المراجعة",
    "createdAt": "2025-01-20T10:00:00.000Z"
  }
}
```

---

### Withdraw Funds

**Endpoint:** `POST /api/me/wallet/withdraw`

**Description:** Requests a withdrawal. The requested amount is **immediately deducted** (held) from the user's balance to prevent double-spending and tagged as `pending`. If rejected, it should be refunded manually by admin.

**Request:**
```http
POST /api/me/wallet/withdraw
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "amount": 500,
  "method": "bank_transfer",
  "details": "Account Name: John Doe\nIBAN: EG12345..."
}
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Withdrawal request created successfully",
  "transaction": {
    "user": "user_id",
    "type": "withdraw",
    "amount": 500,
    "status": "pending",
    "adminNote": "Account details...",
    "createdAt": "2025-01-20T10:00:00.000Z"
  },
  "newBalance": 1500
}
```

---

## 📞 Support

For API issues or questions:
- Check error responses for detailed messages
- Verify authentication token is valid
- Ensure required fields are provided
- Check network connectivity
---

## 📊 Reports & Analytics APIs

### School Comprehensive AI Report

**Endpoint:** `GET /api/schools/my/[id]/reports`

**Description:** Generates a comprehensive AI-powered report for the school, analyzing students, attendance, clinic visits, and more. Uses Google Gemini AI for qualitative analysis.

**Response (200 Success):**
```json
{
  "stats": {
    "studentsCount": 150,
    "applicationsCount": 45,
    "attendanceCount": 1200,
    "avgAttendanceRate": "0.92",
    "clinicVisitsCount": 8,
    "classroomsCount": 12,
    "studentIdCardsCount": 5,
    "eventsCount": 3
  },
  "studentsByClass": { ... },
  "markdown": "# 📊 تقرير شامل للمدرسة...",
  "html": "<h1>📊 تقرير شامل للمدرسة</h1>..."
}
```

---

### List Custom Report Templates

**Endpoint:** `GET /api/schools/my/[id]/reports/list`

**Description:** Get the list of available report templates for the school.

**Response (200 Success):**
```json
{
  "reports": [
    {
      "id": "template_id",
      "name": "إحصائيات الطلاب الجدد",
      "code": "STU_STATS_NEW",
      "category": "admission",
      "type": "list"
    }
  ]
}
```

---

### Manage Report Templates

#### Create/List Templates
**Endpoint:** `GET/POST /api/schools/my/[id]/reports/templates`

#### Update/Delete Template
**Endpoint:** `GET/PUT/DELETE /api/schools/my/[id]/reports/templates/[templateId]`

---

_Last updated: January 2024_

---

---

## 📊 Application Status Flow

```
pending → under_review → recommended → accepted
   ↓           ↓              ↓
rejected   rejected      rejected
```

**Status Descriptions:**
- `pending` - Initial status when application is submitted
- `under_review` - School is reviewing (usually after interview is scheduled)
- `recommended` - Recommended for acceptance (optional intermediate status)
- `accepted` - Application accepted
- `rejected` - Application rejected
- `draft` - Draft (not yet submitted)

**Status Transitions:**
- When interview is scheduled → status automatically changes to `under_review`
- Status can be changed directly by school admin
- Each status change creates an event in the timeline

---

## 🔔 Email Notifications

### When Interview is Scheduled
- **Recipient:** Parent
- **Subject:** "📅 تم تحديد موعد المقابلة - [School Name]"
- **Content:** Includes interview date, time, location, and notes

### When Application Status Changes
- Status changes are logged in events but don't trigger emails (can be added if needed)

---

## 📝 Application Events Timeline

Events provide a complete audit trail of application processing:

1. **Automatic Events:**
   - `interview_scheduled` - Created when interview date is set
   - `status_changed` - Created when status is updated

2. **Manual Events:**
   - `note_added` - General notes
   - `interview_attended` - Mark interview as attended
   - `interview_missed` - Mark interview as missed
   - `parent_contacted` - Record parent contact
   - `document_requested` - Request document from parent
   - `document_received` - Confirm document received
   - `other` - Other events

**Event Display:**
- Events are displayed chronologically (newest first)
- Each event shows: type, title, description, date, and creator
- Parents can view events for their applications
- School admins can view and add events

---


---

## 💬 Chat & Messaging APIs

### List Conversations

**Endpoint:** `GET /api/chat/conversations`

**Description:** Fetch a paginated list of conversations for the authenticated user, including unread message counts.

**Request:**
```http
GET /api/chat/conversations?limit=20&skip=0
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` (optional): Number of conversations to return (default: 20)
- `skip` (optional): Number of conversations to skip (default: 0)

**Response (200 Success):**
```json
{
  "conversations": [
    {
      "_id": "conversation_id",
      "type": "direct",
      "participants": [
        {
          "user": {
            "_id": "user_id",
            "name": "User Name",
            "email": "user@example.com",
            "avatar": "url",
            "isOnline": true,
            "lastSeen": "2024-01-20T10:00:00.000Z"
          },
          "lastReadAt": "2024-01-20T10:00:00.000Z"
        }
      ],
      "lastMessage": "message_id",
      "lastMessageAt": "2024-01-20T10:05:00.000Z",
      "unreadCount": 2,
      "createdAt": "2024-01-01T10:00:00.000Z",
      "updatedAt": "2024-01-20T10:05:00.000Z"
    }
  ],
  "pagination": {
    "limit": 20,
    "skip": 0,
    "hasMore": false
  }
}
```

---

### Create Conversation

**Endpoint:** `POST /api/chat/conversations`

**Description:** Create a new conversation (direct or group) or return an existing direct conversation.

**Request:**
```http
POST /api/chat/conversations
Authorization: Bearer <token>
Content-Type: application/json

{
  "participants": ["user_id_1", "user_id_2"],
  "type": "direct"
}
```

**Request Body:**
- `participants`: Array of user IDs (required)
- `type`: "direct" or "group" (default: "direct")
- `name`: Group name (required if type is "group")
- `description`: Group description (optional)

**Response (200 Success):**
```json
{
  "conversation": {
    "_id": "conversation_id",
    "type": "direct",
    "participants": [ ... ],
    "createdAt": "...",
    "updatedAt": "..."
  },
  "isNew": true
}
```

---

### Get Messages

**Endpoint:** `GET /api/chat/conversations/[id]/messages`

**Description:** Fetch paginated messages for a specific conversation.

**Request:**
```http
GET /api/chat/conversations/[conversation_id]/messages?limit=50&skip=0
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` (optional): (default: 50)
- `skip` (optional): (default: 0)

**Response (200 Success):**
```json
{
  "messages": [
    {
      "_id": "message_id",
      "conversation": "conversation_id",
      "sender": {
        "_id": "user_id",
        "name": "Sender Name",
        "avatar": "url"
      },
      "content": "Hello world",
      "type": "text",
      "status": "sent",
      "createdAt": "2024-01-20T10:05:00.000Z",
      "updatedAt": "2024-01-20T10:05:00.000Z"
    }
  ],
  "pagination": {
    "limit": 50,
    "skip": 0,
    "hasMore": false
  }
}
```

---

### Send Message

**Endpoint:** `POST /api/chat/conversations/[id]/messages`

**Description:** Send a new message to a conversation.

**Request:**
```http
POST /api/chat/conversations/[conversation_id]/messages
Authorization: Bearer <token>
Content-Type: application/json

{
  "content": "Hello there!",
  "type": "text"
}
```

**Request Body:**
- `content`: Message text content
- `type`: "text", "image", "file" (default: "text")
- `replyTo`: ID of message being replied to (optional)
- `attachments`: Array of attachment objects (optional)

**Response (200 Success):**
```json
{
  "message": {
    "_id": "new_message_id",
    "conversation": "conversation_id",
    "sender": "user_id",
    "content": "Hello there!",
    "status": "sent",
    "createdAt": "..."
  }
}
```

---

## 📌 Admission Follow-Up APIs

### Get Application Events

**Endpoint:** `GET /api/me/applications/school/my/[id]/events`

**Description:** Get the timeline of events/notes for a specific application. Available to Parents (own application) and School Staff (school applications).

**Request:**
```http
GET /api/me/applications/school/my/[application_id]/events
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "events": [
    {
      "type": "status_changed",
      "title": "Status Updated",
      "description": "Application status changed from pending to under_review",
      "date": "2024-01-15T10:00:00.000Z",
      "createdBy": {
        "_id": "user_id",
        "name": "Admin Name",
        "role": "school_owner"
      },
      "metadata": {}
    }
  ]
}
```

---

### Add Application Event

**Endpoint:** `POST /api/me/applications/school/my/[id]/events`

**Description:** Add a new event or note to an application. Only available to **School Staff** (Owner, Moderator, Admin).

**Request:**
```http
POST /api/me/applications/school/my/[application_id]/events
Authorization: Bearer <token>
Content-Type: application/json

{
  "type": "note_added",
  "title": "Interview Follow-up",
  "description": "Parent called to confirm attendance.",
  "date": "2024-01-20T14:30:00.000Z"
}
```

**Request Body:**
- `type` (required): Event type. Enum:
   - `note_added`
   - `interview_scheduled`
   - `interview_attended`
   - `interview_missed`
   - `status_changed`
   - `document_requested`
   - `document_received`
   - `parent_contacted`
   - `other`
- `title` (required): Short title for the event
- `description` (optional): Detailed description
- `date` (optional): Event date (defaults to now)
- `metadata` (optional): JSON object with extra data

**Response (200 Success):**
```json
{
  "message": "تم إضافة الحدث بنجاح",
  "event": {
    "type": "note_added",
    "title": "Interview Follow-up",
    "description": "Parent called to confirm attendance.",
    "createdBy": "user_id",
    "date": "2024-01-20T14:30:00.000Z"
  }
}
```

---


---

### Parent: Reply to Event

**Endpoint:** `POST /api/me/applications/[id]/events/reply`

**Description:** Allows a parent to reply to an application event or upload a requested document.

- **:id**: The ID of the Application (not the child ID).

**Request:**
```http
POST /api/me/applications/[application_id]/events/reply
Authorization: Bearer <token>
Content-Type: application/json

{
  "message": "I have attached the birth certificate as requested.",
  "document": {
    "url": "https://storage.googleapis.com/bucket/file123.pdf",
    "label": "birth_certificate",
    "description": "Scanned copy of original"
  }
}
```

**Request Body:**
- `message` (string, optional*): The text comment/reply from the parent.
- `document` (object, optional*): Object containing file details if uploading a file.
   - `url` (string, required): The direct URL of the uploaded file.
   - `label` (string, optional): Type of document (e.g., `birth_certificate`, `national_id`).
   - `description` (string, optional): Optional note about the file.

*\*At least one of `message` or `document` must be provided.*

**Response (200 Success):**
```json
{
  "message": "Reply added successfully",
  "event": {
    "type": "document_received", 
    "title": "Parent Reply (Document Attached)",
    "description": "I have attached...",
    "date": "2024-03-20T10:00:00.000Z",
    "metadata": {
      "hasAttachment": true,
      "attachmentUrl": "https://storage..."
    }
  }
}
```

---

## 👨‍🏫 Teachers Management APIs

All teacher endpoints are scoped to a specific school and require authentication. Access is typically restricted to **School Owners**, **Moderators**, or **Admins**.

### List Teachers

**Endpoint:** `GET /api/schools/my/[id]/teachers`

**Description:** Fetch a paginated list of all teachers belonging to a specific school.

**Request:**
```http
GET /api/schools/my/[school_id]/teachers?limit=20&page=1
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` (optional): Number of teachers per page
- `page` (optional): Page number (default: 1)

**Response (200 Success):**
```json
{
  "teachers": [
    {
      "_id": "teacher_id",
      "name": "Teacher Name",
      "email": "teacher@school.com",
      "role": "teacher",
      "teacher": {
        "employeeId": "EMP001",
        "subjects": [ { "_id": "...", "name": "Math", "grade": { "name": "Grade 10" } } ],
        "gradeLevels": [ { "_id": "...", "name": "Grade 10" } ],
        "class": [ { "_id": "...", "name": "10-A", "grade": { "name": "Grade 10" } } ],
        "hireDate": "2024-01-01T00:00:00Z"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 50,
    "pages": 3,
    "hasMore": true
  }
}
```

---

### Create Teacher

**Endpoint:** `POST /api/schools/my/[id]/teachers`

**Description:** Create a new teacher account and assign them to the specified school.

**Request:**
```http
POST /api/schools/my/[school_id]/teachers
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john.doe@school.com",
  "password": "securePassword123",
  "username": "johndoe",
  "employeeId": "TCH-001",
  "subjects": ["subject_id_1", "subject_id_2"],
  "gradeLevels": ["grade_id_1"],
  "classList": ["class_id_1"],
  "salary": 5000,
  "employmentType": "full_time",
  "hireDate": "2024-01-01",
  "qualifications": ["B.Sc. Education"],
  "experienceYears": 5,
  "isActive": true
}
```

**Required Fields:**
- `name`
- `email`
- `password`

**Optional Fields:**
- `phone`
- `username`
- `employeeId`
- `subjects` (Array of Subject IDs)
- `gradeLevels` (Array of Grade IDs)
- `classList` (Array of Class IDs)
- `hireDate` (Date string)
- `salary` (Number)
- `employmentType` (String: "full_time", "part_time", etc.)
- `qualifications` (Array of Strings)
- `experienceYears` (Number)
- `moodlePassword` (String)

---

### Get Single Teacher Detail

**Endpoint:** `GET /api/schools/my/[id]/teachers/[teacherId]`

**Description:** Retrieve comprehensive details for a specific teacher, including school, subjects, and grade levels.

**Request:**
```http
GET /api/schools/my/[school_id]/teachers/[teacher_id]
Authorization: Bearer <token>
```

**Response (200 Success):**
```json
{
  "teacher": {
    "_id": "teacher_id",
    "name": "John Doe",
    "email": "john.doe@school.com",
    "teacher": {
      "school": { "_id": "...", "name": "School Name" },
      "subjects": [...],
      "gradeLevels": [...],
      "timetable": [...]
    }
  }
}
```

---

### Update Teacher

**Endpoint:** `PUT /api/schools/my/[id]/teachers/[teacherId]`

**Description:** Update a teacher's profile, employment details, or account status.

**Request:**
```http
PUT /api/schools/my/[school_id]/teachers/[teacher_id]
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "John Updated",
  "salary": 5500,
  "isActive": true,
  "subjects": ["new_subject_id"],
  "experienceYears": 6
}
```

---

### Update Teacher Timetable

**Endpoint:** `PUT /api/schools/my/[id]/teachers/[teacherId]/timetable`

**Description:** Update the weekly teaching schedule for a specific teacher.

**Request:**
```http
PUT /api/schools/my/[school_id]/teachers/[teacher_id]/timetable
Authorization: Bearer <token>
Content-Type: application/json

{
  "timetable": [
    {
      "day": "Monday",
      "subject": "subject_id",
      "gradeLevel": "grade_id",
      "startTime": "08:00",
      "endTime": "09:00"
    }
  ]
}
```

---

### Delete Teacher

**Endpoint:** `DELETE /api/schools/my/[id]/teachers/[teacherId]`

**Description:** Permanently delete a teacher user from the system.

**Request:**
```http
DELETE /api/schools/my/[school_id]/teachers/[teacher_id]
Authorization: Bearer <token>
```

---

## 👨‍👩‍👧 Parent: Messaging Child's Teachers

This workflow explains how a parent can find the teachers assigned to their child and start a chat conversation with them.

### Step 1: Get Child & Class Info
First, retrieve your child's profile to get their `schoolId` and `class` (Classroom) ID.

**Endpoint:** `GET /api/children/get-related`

**Snippet:**
```json
{
  "children": [
    {
      "_id": "child_id",
      "fullName": "Child Name",
      "schoolId": "school_id",
      "class": {
        "_id": "class_id",
        "name": "1-A"
      }
    }
  ]
}
```

---

### Step 2: Get Class Teachers
Use the `schoolId` and `class_id` from Step 1 to fetch the list of teachers assigned to your child's specific classroom.

**Endpoint:** `GET /api/schools/my/[schoolId]/classes/[classId]`

**Response (200 OK):**
```json
{
  "class": { ... },
  "teachers": [
    {
      "_id": "teacher_user_id",
      "name": "Teacher Name",
      "avatar": "...",
      "role": "teacher"
    }
  ]
}
```

---

### Step 3: Start a Conversation
Once you have the `teacher_user_id`, create or retrieve a direct chat conversation with them.

**Endpoint:** `POST /api/chat/conversations`
**Body:**
```json
{
  "participants": ["teacher_user_id"],
  "type": "direct"
}
```

**Response:**
```json
{
  "conversation": {
    "_id": "conv_id",
    "type": "direct"
  }
}
```

---

### Step 4: Send the Message
Use the `conv_id` from Step 3 to send your message.

**Endpoint:** `POST /api/chat/conversations/[conv_id]/messages`
**Body:**
```json
{
  "content": "Hello Teacher, I wanted to ask about my child's progress.",
  "type": "text"
}
```

---


---

## 14. Store & E-commerce APIs

This section covers the Store APIs including Product Management, Cart (DB-Synced), and Order Checkout.

### Base URL
`/api/store`

### Authentication
All Cart and Checkout APIs require a Bearer Token in the `Authorization` header.
`Authorization: Bearer <token>`

### List Products
- **URL:** `/api/store/products?category=<id>&search=query&featured=true`
- **Method:** `GET`

### Get Product Details
- **URL:** `/api/store/products/[id]`
- **Method:** `GET`

### Cart Management (DB-Synced)
The cart is now stored in the database, allowing synchronization between Web and Mobile apps.

#### Get Cart
Retrieves the current user's cart items with full product details and calculated prices.

- **URL:** `/api/store/cart`
- **Method:** `GET`
- **Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "_id": "cart_item_id",
        "productId": "product_id",
        "product": { "title_en": "Item", "price": 100, "images": [...] },
        "quantity": 2,
        "selections": [{ "name": "Size", "value": "XL" }],
        "price": 90,
        "subtotal": 180
      }
    ],
    "subtotal": 180,
    "total": 180,
    "itemCount": 2
  }
}
```

#### Add/Update Item in Cart
Adds a new item to the cart or increases quantity if identical item exists.

- **URL:** `/api/store/cart`
- **Method:** `POST`
- **Body:**
```json
{
  "productId": "string",
  "quantity": 1,
  "selections": [
    { "name": "Color", "value": "Red" }
  ]
}
```

#### Update Item Quantity
Corrects the quantity of a specific item in the cart.

- **URL:** `/api/store/cart`
- **Method:** `PUT`
- **Body:**
```json
{
  "cartItemId": "string", 
  "quantity": 5
}
```

#### Remove Item / Clear Cart
- **URL:** `/api/store/cart?cartItemId=<id>` (Delete single)
- **URL:** `/api/store/cart?clear=true` (Clear all)
- **Method:** `DELETE`

### Orders & Checkout

#### Create Order (Checkout)
Creates an order. If `items` are not provided, it automatically checks out the user's current DB cart.

- **URL:** `/api/store/orders`
- **Method:** `POST`
- **Body:**
```json
{
  "paymentMethod": "wallet", 
  "deliveryMethod": "pickup",
  "shippingAddress": {
     "address": "123 Street",
     "city": "Cairo",
     "phone": "0123456789"
  },
  "notes": "Please deliver after 5 PM",
  "school": "optional_school_id"
}
```
*Note: If `paymentMethod` is `wallet`, the balance is deducted automatically.*

#### Get Order History
- **URL:** `/api/store/orders?page=1&limit=10&status=pending`
- **Method:** `GET`

---


---

## 15. Notifications APIs

### List Notifications

**Endpoint:** `GET /api/notifications`

**Description:** Fetch notifications for the authenticated user (Parent or Teacher). Returns a list of notifications and the count of unread notifications.

**Request:**
```http
GET /api/notifications?limit=20
Authorization: Bearer <token>
```

**Query Parameters:**
- `limit` (optional): Number of notifications to return (default: 20)

**Response (200 OK):**
```json
{
  "notifications": [
    {
      "_id": "notification_id",
      "recipient": "user_id",
      "type": "application_status_update",
      "title": "Application Status Changed",
      "message": "Your application for John has been approved.",
      "status": "unread",
      "createdAt": "2024-03-20T10:00:00.000Z",
      "school": { "name": "School Name", "logoUrl": "..." },
      "student": { "name": "John" },
      "application": { "status": "approved" }
    }
  ],
  "unreadCount": 5
}
```

### Mark All Read

**Endpoint:** `POST /api/notifications/read-all`

**Description:** Mark all notifications as read for a specific user.

**Request:**
```http
POST /api/notifications/read-all?userId=user_id
Authorization: Bearer <token>
```

**Query Parameters:**
- `userId` (required): The ID of the user whose notifications should be marked as read.

**Response (200 OK):**
```json
{
  "message": "All notifications marked as read",
  "modifiedCount": 5
}
```

### Create Notification (System)

**Endpoint:** `POST /api/notifications`

**Description:** Create a new notification (typically used by internal system processes).

**Request:**
```http
POST /api/notifications
Authorization: Bearer <token>
Content-Type: application/json

{
  "recipient": "user_id",
  "type": "custom",
  "title": "Welcome!",
  "message": "Welcome to our platform.",
  "school": "school_id"
}
```

---

_Last updated: February 2026_
this is bus details controller
add to app
and line details too

import { NextResponse } from "next/server";
import { dbConnect } from "@/lib/dbConnect";
import { authenticate } from "@/middlewares/auth";
import BusLine from "@/models/BusLine";

// POST - Mark station as departed
export async function POST(req, { params }) {
    try {
        await dbConnect();
        const user = await authenticate(req);
        if (!user || user.message) {
            return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
        }

        const { id: schoolId, busId, lineId, stationOrder } = await params;
        if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24 || !lineId || lineId.length !== 24) {
            return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
        }

        const order = parseInt(stationOrder);
        if (isNaN(order)) {
            return NextResponse.json({ message: "رقم المحطة غير صالح" }, { status: 400 });
        }

        const busLine = await BusLine.findOne({
            _id: lineId,
            bus: busId,
            school: schoolId,
        });

        if (!busLine) {
            return NextResponse.json({ message: "خط الحافلة غير موجود" }, { status: 404 });
        }

        await busLine.markStationDeparted(order);

        const updatedBusLine = await BusLine.findById(lineId)
            .populate("stations.students.student", "fullName studentCode")
            .lean();

        return NextResponse.json(
            { message: "تم تسجيل مغادرة الحافلة من المحطة", busLine: updatedBusLine },
            { status: 200 }
        );
    } catch (error) {
        console.error("Error marking station departure:", error);
        return NextResponse.json(
            { message: "حدث خطأ أثناء تسجيل مغادرة الحافلة", error: error.message },
            { status: 500 }
        );
    }
}import { NextResponse } from "next/server";
import { dbConnect } from "@/lib/dbConnect";
import { authenticate } from "@/middlewares/auth";
import BusLine from "@/models/BusLine";
import StudentAttendance from "@/models/StudentAttendance";

// POST - Update student attendance at a station
export async function POST(req, { params }) {
    try {
        await dbConnect();
        const user = await authenticate(req);
        if (!user || user.message) {
            return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
        }

        const { id: schoolId, busId, lineId, stationOrder } = await params;
        if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24 || !lineId || lineId.length !== 24) {
            return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
        }

        const order = parseInt(stationOrder);
        if (isNaN(order)) {
            return NextResponse.json({ message: "رقم المحطة غير صالح" }, { status: 400 });
        }

        const busLine = await BusLine.findOne({
            _id: lineId,
            bus: busId,
            school: schoolId,
        });

        if (!busLine) {
            return NextResponse.json({ message: "خط الحافلة غير موجود" }, { status: 404 });
        }

        const body = await req.json();
        const { studentId, attendanceStatus, attendanceTime, notes } = body;

        if (!studentId || !attendanceStatus) {
            return NextResponse.json(
                { message: "الرجاء إدخال معرف الطالب وحالة الحضور" },
                { status: 400 }
            );
        }

        // Validate attendance status
        const validStatuses = ["present", "absent", "late", "no_show"];
        if (!validStatuses.includes(attendanceStatus)) {
            return NextResponse.json(
                { message: "حالة الحضور غير صالحة" },
                { status: 400 }
            );
        }

        // Update attendance in bus line
        await busLine.updateStationAttendance(
            order,
            studentId,
            attendanceStatus,
            attendanceTime ? new Date(attendanceTime) : null,
            user._id,
            notes
        );

        // Also create/update student attendance record
        const station = busLine.stations.find((s) => s.order === order);
        const studentRecord = station?.students.find(
            (s) => s.student.toString() === studentId.toString()
        );

        if (studentRecord) {
            // Create attendance record for the student
            const attendanceDate = new Date(busLine.date);
            attendanceDate.setHours(0, 0, 0, 0);

            await StudentAttendance.findOneAndUpdate(
                {
                    school: schoolId,
                    child: studentId,
                    date: attendanceDate,
                },
                {
                    school: schoolId,
                    child: studentId,
                    date: attendanceDate,
                    status: attendanceStatus === "present" ? "present" : attendanceStatus === "late" ? "late" : "absent",
                    checkInTime: attendanceStatus === "present" || attendanceStatus === "late" ? (attendanceTime ? new Date(attendanceTime) : new Date()) : null,
                    method: "manual",
                    location: station.coordinates ? {
                        latitude: station.coordinates.lat,
                        longitude: station.coordinates.lng,
                        address: station.address,
                    } : undefined,
                    notes: notes || `Bus attendance at station: ${station.name}`,
                    recordedBy: user._id,
                },
                { upsert: true, new: true }
            );
        }

        // Reload bus line with populated data
        const updatedBusLine = await BusLine.findById(lineId)
            .populate("stations.students.student", "fullName studentCode")
            .populate("stations.students.recordedBy", "name email")
            .lean();

        return NextResponse.json(
            { message: "تم تحديث حضور الطالب بنجاح", busLine: updatedBusLine },
            { status: 200 }
        );
    } catch (error) {
        console.error("Error updating station attendance:", error);
        return NextResponse.json(
            { message: "حدث خطأ أثناء تحديث حضور الطالب", error: error.message },
            { status: 500 }
        );
    }
}

// PUT - Bulk update attendance for multiple students at a station
export async function PUT(req, { params }) {
    try {
        await dbConnect();
        const user = await authenticate(req);
        if (!user || user.message) {
            return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
        }

        const { id: schoolId, busId, lineId, stationOrder } = await params;
        if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24 || !lineId || lineId.length !== 24) {
            return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
        }

        const order = parseInt(stationOrder);
        if (isNaN(order)) {
            return NextResponse.json({ message: "رقم المحطة غير صالح" }, { status: 400 });
        }

        const busLine = await BusLine.findOne({
            _id: lineId,
            bus: busId,
            school: schoolId,
        });

        if (!busLine) {
            return NextResponse.json({ message: "خط الحافلة غير موجود" }, { status: 404 });
        }

        const body = await req.json();
        const { attendanceRecords } = body; // Array of { studentId, attendanceStatus, attendanceTime, notes }

        if (!attendanceRecords || !Array.isArray(attendanceRecords) || attendanceRecords.length === 0) {
            return NextResponse.json(
                { message: "الرجاء إدخال سجلات الحضور" },
                { status: 400 }
            );
        }

        const station = busLine.stations.find((s) => s.order === order);
        if (!station) {
            return NextResponse.json({ message: "المحطة غير موجودة" }, { status: 404 });
        }

        // Update all attendance records
        const attendancePromises = attendanceRecords.map(async (record) => {
            const { studentId, attendanceStatus, attendanceTime, notes } = record;

            if (!studentId || !attendanceStatus) {
                return null;
            }

            // Update in bus line
            await busLine.updateStationAttendance(
                order,
                studentId,
                attendanceStatus,
                attendanceTime ? new Date(attendanceTime) : null,
                user._id,
                notes
            );

            // Create/update student attendance record
            const attendanceDate = new Date(busLine.date);
            attendanceDate.setHours(0, 0, 0, 0);

            return StudentAttendance.findOneAndUpdate(
                {
                    school: schoolId,
                    child: studentId,
                    date: attendanceDate,
                },
                {
                    school: schoolId,
                    child: studentId,
                    date: attendanceDate,
                    status: attendanceStatus === "present" ? "present" : attendanceStatus === "late" ? "late" : "absent",
                    checkInTime: attendanceStatus === "present" || attendanceStatus === "late" ? (attendanceTime ? new Date(attendanceTime) : new Date()) : null,
                    method: "manual",
                    location: station.coordinates ? {
                        latitude: station.coordinates.lat,
                        longitude: station.coordinates.lng,
                        address: station.address,
                    } : undefined,
                    notes: notes || `Bus attendance at station: ${station.name}`,
                    recordedBy: user._id,
                },
                { upsert: true, new: true }
            );
        });

        await Promise.all(attendancePromises.filter((p) => p !== null));

        // Reload bus line with populated data
        const updatedBusLine = await BusLine.findById(lineId)
            .populate("stations.students.student", "fullName studentCode")
            .populate("stations.students.recordedBy", "name email")
            .lean();

        return NextResponse.json(
            { message: "تم تحديث حضور الطلاب بنجاح", busLine: updatedBusLine },
            { status: 200 }
        );
    } catch (error) {
        console.error("Error bulk updating station attendance:", error);
        return NextResponse.json(
            { message: "حدث خطأ أثناء تحديث حضور الطلاب", error: error.message },
            { status: 500 }
        );
    }
}import { NextResponse } from "next/server";
import { dbConnect } from "@/lib/dbConnect";
import { authenticate } from "@/middlewares/auth";
import BusLine from "@/models/BusLine";

// POST - Mark station as arrived
export async function POST(req, { params }) {
    try {
        await dbConnect();
        const user = await authenticate(req);
        if (!user || user.message) {
            return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
        }

        const { id: schoolId, busId, lineId, stationOrder } = await params;
        if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24 || !lineId || lineId.length !== 24) {
            return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
        }

        const order = parseInt(stationOrder);
        if (isNaN(order)) {
            return NextResponse.json({ message: "رقم المحطة غير صالح" }, { status: 400 });
        }

        const busLine = await BusLine.findOne({
            _id: lineId,
            bus: busId,
            school: schoolId,
        });

        if (!busLine) {
            return NextResponse.json({ message: "خط الحافلة غير موجود" }, { status: 404 });
        }

        await busLine.markStationArrived(order);

        const updatedBusLine = await BusLine.findById(lineId)
            .populate("stations.students.student", "fullName studentCode")
            .lean();

        return NextResponse.json(
            { message: "تم تسجيل وصول الحافلة إلى المحطة", busLine: updatedBusLine },
            { status: 200 }
        );
    } catch (error) {
        console.error("Error marking station arrival:", error);
        return NextResponse.json(
            { message: "حدث خطأ أثناء تسجيل وصول الحافلة", error: error.message },
            { status: 500 }
        );
    }
}
import { NextResponse } from "next/server";
import { dbConnect } from "@/lib/dbConnect";
import { authenticate } from "@/middlewares/auth";
import Bus from "@/models/Bus";
import School from "@/models/School";
import User from "@/models/User";

// GET - Get a specific bus
export async function GET(req, { params }) {
  try {
    await dbConnect();
    const user = await authenticate(req);
    if (!user || user.message) {
      return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
    }

    const { id: schoolId, busId } = await params;
    if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24) {
      return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
    }

    const bus = await Bus.findOne({ _id: busId, school: schoolId })
      .populate("driver", "name email phone username avatar")
      .populate("assistant", "name email phone username avatar")
      .populate("assignedStudents.student", "fullName studentCode stage grade class")
      .populate("assignedStudents.student.stage", "name")
      .populate("assignedStudents.student.grade", "name")
      .populate("assignedStudents.student.class", "name")
      .lean();

    if (!bus) {
      return NextResponse.json({ message: "الحافلة غير موجودة" }, { status: 404 });
    }

    return NextResponse.json({ bus }, { status: 200 });
  } catch (error) {
    console.error("Error fetching bus:", error);
    return NextResponse.json(
      { message: "حدث خطأ أثناء جلب بيانات الحافلة", error: error.message },
      { status: 500 }
    );
  }
}

// PUT - Update a bus
export async function PUT(req, { params }) {
  try {
    await dbConnect();
    const user = await authenticate(req);
    if (!user || user.message) {
      return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
    }

    const { id: schoolId, busId } = await params;
    if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24) {
      return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
    }

    const bus = await Bus.findOne({ _id: busId, school: schoolId });
    if (!bus) {
      return NextResponse.json({ message: "الحافلة غير موجودة" }, { status: 404 });
    }

    const body = await req.json();
    const {
      busNumber,
      plateNumber,
      motorNumber,
      chassisNumber,
      capacity,
      driver,
      assistant,
      status,
      busType,
      manufacturer,
      model,
      year,
      color,
      insurance,
      registration,
      inspection,
      gps,
      gpsEnabled,
      gpsDeviceId,
      routes,
      notes,
      isActive,
    } = body;

    // Check for duplicate bus number, plate number, motor number, or chassis number
    if (busNumber || plateNumber || motorNumber || chassisNumber) {
      const existingBus = await Bus.findOne({
        school: schoolId,
        _id: { $ne: busId },
        $or: [
          ...(busNumber ? [{ busNumber }] : []),
          ...(plateNumber ? [{ plateNumber }] : []),
          ...(motorNumber ? [{ motorNumber: motorNumber.toUpperCase() }] : []),
          ...(chassisNumber ? [{ chassisNumber: chassisNumber.toUpperCase() }] : []),
        ],
      });

      if (existingBus) {
        let message = "رقم الحافلة أو لوحة الأرقام موجود بالفعل";
        if (existingBus.motorNumber === motorNumber?.toUpperCase()) {
          message = "رقم المحرك موجود بالفعل";
        } else if (existingBus.chassisNumber === chassisNumber?.toUpperCase()) {
          message = "رقم الشاصي موجود بالفعل";
        }
        return NextResponse.json({ message }, { status: 400 });
      }
    }

    // Validate driver if provided
    if (driver !== undefined) {
      if (driver) {
        const driverUser = await User.findById(driver);
        if (!driverUser) {
          return NextResponse.json({ message: "السائق غير موجود" }, { status: 400 });
        }
        bus.driver = driver;
      } else {
        bus.driver = null;
      }
    }

    // Validate assistant if provided
    if (assistant !== undefined) {
      if (assistant) {
        const assistantUser = await User.findById(assistant);
        if (!assistantUser) {
          return NextResponse.json({ message: "المساعد غير موجود" }, { status: 400 });
        }
        bus.assistant = assistant;
      } else {
        bus.assistant = null;
      }
    }

    // Update fields
    if (busNumber) bus.busNumber = busNumber;
    if (plateNumber) bus.plateNumber = plateNumber;
    if (motorNumber) bus.motorNumber = motorNumber.toUpperCase();
    if (chassisNumber) bus.chassisNumber = chassisNumber.toUpperCase();
    if (capacity !== undefined) {
      bus.capacity = capacity;
      // Ensure currentOccupancy doesn't exceed new capacity
      if (bus.currentOccupancy > capacity) {
        bus.currentOccupancy = capacity;
      }
    }
    if (status) bus.status = status;
    if (busType) bus.busType = busType;
    if (manufacturer !== undefined) bus.manufacturer = manufacturer;
    if (model !== undefined) bus.model = model;
    if (year !== undefined) bus.year = year;
    if (color !== undefined) bus.color = color;
    if (insurance) bus.insurance = insurance;
    if (registration) bus.registration = registration;
    if (inspection) bus.inspection = inspection;
    if (gpsEnabled !== undefined || gpsDeviceId !== undefined || gps) {
      bus.gps = {
        enabled: gpsEnabled !== undefined ? gpsEnabled : (gps?.enabled ?? bus.gps?.enabled ?? false),
        deviceId: gpsDeviceId || gps?.deviceId || bus.gps?.deviceId || "",
        trackingUrl: gps?.trackingUrl || bus.gps?.trackingUrl || "",
      };
    }
    if (routes) bus.routes = routes;
    if (notes !== undefined) bus.notes = notes;
    if (isActive !== undefined) bus.isActive = isActive;

    await bus.save();
    await bus.populate("driver", "name email phone username");
    await bus.populate("assistant", "name email phone username");
    await bus.populate("assignedStudents.student", "fullName studentCode");

    return NextResponse.json(
      { message: "تم تحديث الحافلة بنجاح", bus },
      { status: 200 }
    );
  } catch (error) {
    console.error("Error updating bus:", error);
    if (error.code === 11000) {
      return NextResponse.json(
        { message: "رقم الحافلة أو لوحة الأرقام أو رقم المحرك أو رقم الشاصي موجود بالفعل" },
        { status: 400 }
      );
    }
    return NextResponse.json(
      { message: "حدث خطأ أثناء تحديث الحافلة", error: error.message },
      { status: 500 }
    );
  }
}

// DELETE - Delete a bus
export async function DELETE(req, { params }) {
  try {
    await dbConnect();
    const user = await authenticate(req);
    if (!user || user.message) {
      return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
    }

    const { id: schoolId, busId } = await params;
    if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24) {
      return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
    }

    const bus = await Bus.findOne({ _id: busId, school: schoolId });
    if (!bus) {
      return NextResponse.json({ message: "الحافلة غير موجودة" }, { status: 404 });
    }

    // Check if bus has assigned students
    const activeAssignments = bus.assignedStudents.filter(
      (assignment) => assignment.status === "active"
    );

    if (activeAssignments.length > 0) {
      return NextResponse.json(
        {
          message: `لا يمكن حذف الحافلة لأنها تحتوي على ${activeAssignments.length} طالب مسجل`,
        },
        { status: 400 }
      );
    }

    await Bus.findByIdAndDelete(busId);

    return NextResponse.json({ message: "تم حذف الحافلة بنجاح" }, { status: 200 });
  } catch (error) {
    console.error("Error deleting bus:", error);
    return NextResponse.json(
      { message: "حدث خطأ أثناء حذف الحافلة", error: error.message },
      { status: 500 }
    );
  }
}

import { NextResponse } from "next/server";
import { dbConnect } from "@/lib/dbConnect";
import { authenticate } from "@/middlewares/auth";
import Bus from "@/models/Bus";

// GET - Get all routes for a bus
export async function GET(req, { params }) {
  try {
    await dbConnect();
    const user = await authenticate(req);
    if (!user || user.message) {
      return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
    }

    const { id: schoolId, busId } = await params;
    if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24) {
      return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
    }

    const bus = await Bus.findOne({ _id: busId, school: schoolId }).lean();
    if (!bus) {
      return NextResponse.json({ message: "الحافلة غير موجودة" }, { status: 404 });
    }

    const { searchParams } = new URL(req.url);
    const isActive = searchParams.get("isActive");

    let routes = bus.routes || [];
    if (isActive !== null) {
      routes = routes.filter((route) => route.isActive === (isActive === "true"));
    }

    return NextResponse.json({ routes }, { status: 200 });
  } catch (error) {
    console.error("Error fetching bus routes:", error);
    return NextResponse.json(
      { message: "حدث خطأ أثناء جلب بيانات الخطوط", error: error.message },
      { status: 500 }
    );
  }
}

// POST - Add a new route to a bus
export async function POST(req, { params }) {
  try {
    await dbConnect();
    const user = await authenticate(req);
    if (!user || user.message) {
      return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
    }

    const { id: schoolId, busId } = await params;
    if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24) {
      return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
    }

    const bus = await Bus.findOne({ _id: busId, school: schoolId });
    if (!bus) {
      return NextResponse.json({ message: "الحافلة غير موجودة" }, { status: 404 });
    }

    const body = await req.json();
    const { name, description, stops, schedule, isActive } = body;

    if (!name) {
      return NextResponse.json({ message: "الرجاء إدخال اسم الخط" }, { status: 400 });
    }

    // Check if route name already exists
    const existingRoute = bus.routes.find((r) => r.name === name);
    if (existingRoute) {
      return NextResponse.json({ message: "اسم الخط موجود بالفعل" }, { status: 400 });
    }

    // Add route
    bus.routes.push({
      name,
      description: description || "",
      stops: stops || [],
      schedule: schedule || {
        morning: { pickupTime: "", returnTime: "" },
        afternoon: { pickupTime: "", returnTime: "" },
      },
      isActive: isActive !== undefined ? isActive : true,
    });

    await bus.save();

    return NextResponse.json(
      { message: "تم إضافة الخط بنجاح", bus },
      { status: 200 }
    );
  } catch (error) {
    console.error("Error adding route:", error);
    return NextResponse.json(
      { message: "حدث خطأ أثناء إضافة الخط", error: error.message },
      { status: 500 }
    );
  }
}

// PUT - Update a route
export async function PUT(req, { params }) {
  try {
    await dbConnect();
    const user = await authenticate(req);
    if (!user || user.message) {
      return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
    }

    const { id: schoolId, busId } = await params;
    if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24) {
      return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
    }

    const bus = await Bus.findOne({ _id: busId, school: schoolId });
    if (!bus) {
      return NextResponse.json({ message: "الحافلة غير موجودة" }, { status: 404 });
    }

    const body = await req.json();
    const { routeId, name, description, stops, schedule, isActive } = body;

    if (!routeId) {
      return NextResponse.json({ message: "الرجاء تحديد الخط" }, { status: 400 });
    }

    const route = bus.routes.id(routeId);
    if (!route) {
      return NextResponse.json({ message: "الخط غير موجود" }, { status: 404 });
    }

    // Check if new name conflicts with existing route
    if (name && name !== route.name) {
      const existingRoute = bus.routes.find((r) => r.name === name && r._id.toString() !== routeId);
      if (existingRoute) {
        return NextResponse.json({ message: "اسم الخط موجود بالفعل" }, { status: 400 });
      }
    }

    // Update route fields
    if (name) route.name = name;
    if (description !== undefined) route.description = description;
    if (stops) route.stops = stops;
    if (schedule) route.schedule = schedule;
    if (isActive !== undefined) route.isActive = isActive;

    await bus.save();

    return NextResponse.json(
      { message: "تم تحديث الخط بنجاح", bus },
      { status: 200 }
    );
  } catch (error) {
    console.error("Error updating route:", error);
    return NextResponse.json(
      { message: "حدث خطأ أثناء تحديث الخط", error: error.message },
      { status: 500 }
    );
  }
}

// DELETE - Delete a route
export async function DELETE(req, { params }) {
  try {
    await dbConnect();
    const user = await authenticate(req);
    if (!user || user.message) {
      return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
    }

    const { id: schoolId, busId } = await params;
    if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24) {
      return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
    }

    const bus = await Bus.findOne({ _id: busId, school: schoolId });
    if (!bus) {
      return NextResponse.json({ message: "الحافلة غير موجودة" }, { status: 404 });
    }

    const { searchParams } = new URL(req.url);
    const routeId = searchParams.get("routeId");

    if (!routeId) {
      return NextResponse.json({ message: "الرجاء تحديد الخط" }, { status: 400 });
    }

    const route = bus.routes.id(routeId);
    if (!route) {
      return NextResponse.json({ message: "الخط غير موجود" }, { status: 404 });
    }

    // Check if route has assigned students
    const studentsOnRoute = bus.assignedStudents.filter(
      (assignment) => assignment.route === route.name && assignment.status === "active"
    );

    if (studentsOnRoute.length > 0) {
      return NextResponse.json(
        {
          message: `لا يمكن حذف الخط لأنه يحتوي على ${studentsOnRoute.length} طالب مسجل`,
        },
        { status: 400 }
      );
    }

    // Remove route
    bus.routes.pull(routeId);
    await bus.save();

    return NextResponse.json({ message: "تم حذف الخط بنجاح" }, { status: 200 });
  } catch (error) {
    console.error("Error deleting route:", error);
    return NextResponse.json(
      { message: "حدث خطأ أثناء حذف الخط", error: error.message },
      { status: 500 }
    );
  }
}

import { NextResponse } from "next/server";
import { dbConnect } from "@/lib/dbConnect";
import { authenticate } from "@/middlewares/auth";
import Bus from "@/models/Bus";

// GET - Get current location and location history
export async function GET(req, { params }) {
  try {
    await dbConnect();
    const user = await authenticate(req);
    if (!user || user.message) {
      return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
    }

    const { id: schoolId, busId } = await params;
    if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24) {
      return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
    }

    const bus = await Bus.findOne({ _id: busId, school: schoolId }).lean();
    if (!bus) {
      return NextResponse.json({ message: "الحافلة غير موجودة" }, { status: 404 });
    }

    const { searchParams } = new URL(req.url);
    const hours = parseInt(searchParams.get("hours")) || 24; // Default to last 24 hours

    // Get location history for specified hours
    const since = new Date();
    since.setHours(since.getHours() - hours);

    const history = (bus.locationHistory || []).filter(
      (location) => new Date(location.timestamp) >= since
    );

    return NextResponse.json({
      currentLocation: bus.currentLocation || null,
      locationHistory: history,
      gpsEnabled: bus.gps?.enabled || false,
    });
  } catch (error) {
    console.error("Error fetching bus location:", error);
    return NextResponse.json(
      { message: "حدث خطأ أثناء جلب موقع الحافلة", error: error.message },
      { status: 500 }
    );
  }
}

// POST - Update bus location
export async function POST(req, { params }) {
  try {
    await dbConnect();
    const user = await authenticate(req);
    if (!user || user.message) {
      return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
    }

    const { id: schoolId, busId } = await params;
    if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24) {
      return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
    }

    const bus = await Bus.findOne({ _id: busId, school: schoolId });
    if (!bus) {
      return NextResponse.json({ message: "الحافلة غير موجودة" }, { status: 404 });
    }

    const body = await req.json();
    const { lat, lng, address, speed, heading, accuracy } = body;

    if (!lat || !lng) {
      return NextResponse.json(
        { message: "الرجاء إدخال الإحداثيات" },
        { status: 400 }
      );
    }

    // Update current location
    bus.currentLocation = {
      coordinates: { lat, lng },
      address: address || "",
      speed: speed || 0,
      heading: heading || 0,
      lastUpdated: new Date(),
      accuracy: accuracy || null,
    };

    // Add to location history (keep last 1000 points)
    const locationPoint = {
      coordinates: { lat, lng },
      address: address || "",
      speed: speed || 0,
      heading: heading || 0,
      timestamp: new Date(),
      accuracy: accuracy || null,
    };

    bus.locationHistory = [...(bus.locationHistory || []), locationPoint].slice(-1000);

    await bus.save();

    return NextResponse.json({
      message: "تم تحديث موقع الحافلة بنجاح",
      location: bus.currentLocation,
    });
  } catch (error) {
    console.error("Error updating bus location:", error);
    return NextResponse.json(
      { message: "حدث خطأ أثناء تحديث موقع الحافلة", error: error.message },
      { status: 500 }
    );
  }
}

import { NextResponse } from "next/server";
import { dbConnect } from "@/lib/dbConnect";
import { authenticate } from "@/middlewares/auth";
import BusLine from "@/models/BusLine";
import Bus from "@/models/Bus";
import School from "@/models/School";

// GET - Fetch all bus lines for a bus
export async function GET(req, { params }) {
    try {
        await dbConnect();
        const user = await authenticate(req);
        if (!user || user.message) {
            return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
        }

        const { id: schoolId, busId } = await params;
        if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24) {
            return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
        }

        // Verify bus exists and belongs to school
        const bus = await Bus.findOne({ _id: busId, school: schoolId });
        if (!bus) {
            return NextResponse.json({ message: "الحافلة غير موجودة" }, { status: 404 });
        }

        const { searchParams } = new URL(req.url);
        const date = searchParams.get("date");
        const tripType = searchParams.get("tripType");
        const status = searchParams.get("status");

        let query = { bus: busId, school: schoolId };

        if (date) {
            const startOfDay = new Date(date);
            startOfDay.setHours(0, 0, 0, 0);
            const endOfDay = new Date(date);
            endOfDay.setHours(23, 59, 59, 999);
            query.date = { $gte: startOfDay, $lte: endOfDay };
        }

        if (tripType) {
            query.tripType = tripType;
        }

        if (status) {
            query.status = status;
        }

        const busLines = await BusLine.find(query)
            .populate("driver", "name email phone username")
            .populate("assistant", "name email phone username")
            .populate("stations.students.student", "fullName studentCode")
            .sort({ date: -1, createdAt: -1 })
            .lean();

        return NextResponse.json({ busLines }, { status: 200 });
    } catch (error) {
        console.error("Error fetching bus lines:", error);
        return NextResponse.json(
            { message: "حدث خطأ أثناء جلب بيانات خطوط الحافلة", error: error.message },
            { status: 500 }
        );
    }
}

// POST - Create a new bus line
export async function POST(req, { params }) {
    try {
        await dbConnect();
        const user = await authenticate(req);
        if (!user || user.message) {
            return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
        }

        const { id: schoolId, busId } = await params;
        if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24) {
            return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
        }

        // Verify bus exists and belongs to school
        const bus = await Bus.findOne({ _id: busId, school: schoolId });
        if (!bus) {
            return NextResponse.json({ message: "الحافلة غير موجودة" }, { status: 404 });
        }

        const body = await req.json();
        const { date, tripType, routeName, stations, driver, assistant, notes } = body;

        // Validate required fields
        if (!date || !tripType) {
            return NextResponse.json(
                { message: "الرجاء إدخال التاريخ ونوع الرحلة" },
                { status: 400 }
            );
        }

        // Check if bus line already exists for this bus, date, and trip type
        const existingBusLine = await BusLine.findOne({
            bus: busId,
            date: new Date(date),
            tripType,
        });

        if (existingBusLine) {
            return NextResponse.json(
                { message: "خط الحافلة موجود بالفعل لهذا التاريخ ونوع الرحلة" },
                { status: 400 }
            );
        }

        let busLine;

        // If routeName is provided, create from route
        if (routeName) {
            busLine = await BusLine.createFromRoute(busId, date, tripType, routeName);
        } else if (stations && stations.length > 0) {
            // Create manually with provided stations
            const lineDate = new Date(date);
            lineDate.setHours(0, 0, 0, 0);

            busLine = new BusLine({
                bus: busId,
                school: schoolId,
                date: lineDate,
                tripType,
                routeName: routeName || null,
                stations: stations.map((station, index) => ({
                    ...station,
                    order: station.order || index + 1,
                    status: "pending",
                    students: station.students || [],
                })),
                driver: driver || bus.driver,
                assistant: assistant || bus.assistant,
                status: "scheduled",
                notes,
            });

            await busLine.save();
        } else {
            return NextResponse.json(
                { message: "الرجاء إدخال اسم المسار أو محطات الخط" },
                { status: 400 }
            );
        }

        await busLine.populate("driver", "name email phone username");
        await busLine.populate("assistant", "name email phone username");
        await busLine.populate("stations.students.student", "fullName studentCode");

        return NextResponse.json(
            { message: "تم إنشاء خط الحافلة بنجاح", busLine },
            { status: 201 }
        );
    } catch (error) {
        console.error("Error creating bus line:", error);
        if (error.code === 11000) {
            return NextResponse.json(
                { message: "خط الحافلة موجود بالفعل لهذا التاريخ ونوع الرحلة" },
                { status: 400 }
            );
        }
        return NextResponse.json(
            { message: "حدث خطأ أثناء إنشاء خط الحافلة", error: error.message },
            { status: 500 }
        );
    }
}import { NextResponse } from "next/server";
import { dbConnect } from "@/lib/dbConnect";
import { authenticate } from "@/middlewares/auth";
import BusLine from "@/models/BusLine";
import Bus from "@/models/Bus";

// GET - Get a specific bus line
export async function GET(req, { params }) {
    try {
        await dbConnect();
        const user = await authenticate(req);
        if (!user || user.message) {
            return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
        }

        const { id: schoolId, busId, lineId } = await params;
        if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24 || !lineId || lineId.length !== 24) {
            return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
        }

        const busLine = await BusLine.findOne({
            _id: lineId,
            bus: busId,
            school: schoolId,
        })
            .populate("bus", "busNumber plateNumber")
            .populate("driver", "name email phone username avatar")
            .populate("assistant", "name email phone username avatar")
            .populate("stations.students.student", "fullName studentCode stage grade class")
            .populate("stations.students.recordedBy", "name email")
            .lean();

        if (!busLine) {
            return NextResponse.json({ message: "خط الحافلة غير موجود" }, { status: 404 });
        }

        return NextResponse.json({ busLine }, { status: 200 });
    } catch (error) {
        console.error("Error fetching bus line:", error);
        return NextResponse.json(
            { message: "حدث خطأ أثناء جلب بيانات خط الحافلة", error: error.message },
            { status: 500 }
        );
    }
}

// PUT - Update a bus line
export async function PUT(req, { params }) {
    try {
        await dbConnect();
        const user = await authenticate(req);
        if (!user || user.message) {
            return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
        }

        const { id: schoolId, busId, lineId } = await params;
        if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24 || !lineId || lineId.length !== 24) {
            return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
        }

        const busLine = await BusLine.findOne({
            _id: lineId,
            bus: busId,
            school: schoolId,
        });

        if (!busLine) {
            return NextResponse.json({ message: "خط الحافلة غير موجود" }, { status: 404 });
        }

        const body = await req.json();
        const { stations, driver, assistant, status, notes, tripType } = body;

        // Update fields
        if (stations) busLine.stations = stations;
        if (driver !== undefined) busLine.driver = driver || null;
        if (assistant !== undefined) busLine.assistant = assistant || null;
        if (status) busLine.status = status;
        if (notes !== undefined) busLine.notes = notes;
        if (tripType) busLine.tripType = tripType;

        // Update timestamps based on status
        if (status === "in_progress" && !busLine.startedAt) {
            busLine.startedAt = new Date();
        }
        if (status === "completed" && !busLine.completedAt) {
            busLine.completedAt = new Date();
        }

        await busLine.save();
        await busLine.populate("driver", "name email phone username");
        await busLine.populate("assistant", "name email phone username");
        await busLine.populate("stations.students.student", "fullName studentCode");

        return NextResponse.json(
            { message: "تم تحديث خط الحافلة بنجاح", busLine },
            { status: 200 }
        );
    } catch (error) {
        console.error("Error updating bus line:", error);
        return NextResponse.json(
            { message: "حدث خطأ أثناء تحديث خط الحافلة", error: error.message },
            { status: 500 }
        );
    }
}

// DELETE - Delete a bus line
export async function DELETE(req, { params }) {
    try {
        await dbConnect();
        const user = await authenticate(req);
        if (!user || user.message) {
            return NextResponse.json({ message: "غير مصرح" }, { status: 403 });
        }

        const { id: schoolId, busId, lineId } = await params;
        if (!schoolId || schoolId.length !== 24 || !busId || busId.length !== 24 || !lineId || lineId.length !== 24) {
            return NextResponse.json({ message: "معرف غير صالح" }, { status: 400 });
        }

        const busLine = await BusLine.findOne({
            _id: lineId,
            bus: busId,
            school: schoolId,
        });

        if (!busLine) {
            return NextResponse.json({ message: "خط الحافلة غير موجود" }, { status: 404 });
        }

        // Prevent deletion if line is in progress
        if (busLine.status === "in_progress") {
            return NextResponse.json(
                { message: "لا يمكن حذف خط الحافلة أثناء تنفيذه" },
                { status: 400 }
            );
        }

        await BusLine.findByIdAndDelete(lineId);

        return NextResponse.json({ message: "تم حذف خط الحافلة بنجاح" }, { status: 200 });
    } catch (error) {
        console.error("Error deleting bus line:", error);
        return NextResponse.json(
            { message: "حدث خطأ أثناء حذف خط الحافلة", error: error.message },
            { status: 500 }
        );
    }
}