'use client';

import { useState } from 'react';
import { FiCheck, FiChevronLeft, FiChevronRight, FiBriefcase, FiUsers, FiDatabase, FiLayout, FiFlag, FiBook, FiClock, FiActivity, FiDollarSign } from 'react-icons/fi';
import StepSchoolData from './_components/StepSchoolData';
import StepAcademicSettings from './_components/StepAcademicSettings';
import StepSchoolDetails from './_components/StepSchoolDetails';
import StepWorkingHours from './_components/StepWorkingHours';
import StepFacilities from './_components/StepFacilities';
import StepAccounts from './_components/StepAccounts';
import StepSiteSetup from './_components/StepSiteSetup';
import StepReview from './_components/StepReview';
import { toast } from 'react-hot-toast';
import { useRouter } from 'next/navigation';

const steps = [
    { id: 1, label: 'بيانات المدرسة', icon: FiBriefcase },
    { id: 2, label: 'الاعدادات الاكاديمية', icon: FiBook },
    { id: 3, label: 'البيانات المالية', icon: FiDollarSign },
    { id: 4, label: 'مواعيد العمل', icon: FiClock },
    { id: 5, label: 'المرافق', icon: FiActivity },
    { id: 6, label: 'الحسابات', icon: FiUsers },
    { id: 7, label: 'إعدادات الموقع', icon: FiLayout },
    { id: 8, label: 'إنهاء', icon: FiFlag },
];

export default function SalesOnboardingPage() {
    const router = useRouter();
    const [currentStep, setCurrentStep] = useState(1);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [formData, setFormData] = useState({
        schoolData: {
            name: '',
            type: 'Private',
            feesDetails: { min: 0, max: 0 },
            location: { governorate: '', city: '' }
        },
        ownerData: {
            name: '',
            email: '',
            phone: '',
            password: ''
        },
        moderatorData: {
            name: '',
            email: '',
            phone: '',
            password: ''
        },
        configData: {
            approved: true,
            showInSearch: true,
            theme: { primaryColor: '#3b82f6', secondaryColor: '#1d4ed8' }
        },
        customUsers: []
    });

    const updateFormData = (section, data) => {
        setFormData(prev => ({
            ...prev,
            [section]: { ...prev[section], ...data }
        }));
    };

    const handleNext = async () => {
        if (currentStep === 6) { // Checked at step 6 (Accounts) now
            // 1. Check for Identical Inputs (Owner vs Moderator)
            if (formData.ownerData.email === formData.moderatorData.email) {
                toast.error('لا يمكن استخدام نفس البريد الإلكتروني للمالك والمشرف');
                return;
            }
            if (formData.ownerData.phone === formData.moderatorData.phone) {
                toast.error('لا يمكن استخدام نفس رقم الهاتف للمالك والمشرف');
                return;
            }

            // 2. Validate duplicates via API
            setIsSubmitting(true);
            try {
                // Check Owner
                const resOwner = await fetch('/api/users/check', {
                    method: 'POST', body: JSON.stringify({ email: formData.ownerData.email, phone: formData.ownerData.phone })
                });
                const resultOwner = await resOwner.json();
                if (resultOwner.exists) {
                    toast.error(`بيانات المالك مسجلة مسبقاً: ${formData.ownerData.email || formData.ownerData.phone}`);
                    setIsSubmitting(false);
                    return;
                }

                // Check Moderator
                const resMod = await fetch('/api/users/check', {
                    method: 'POST', body: JSON.stringify({ email: formData.moderatorData.email, phone: formData.moderatorData.phone })
                });
                const resultMod = await resMod.json();
                if (resultMod.exists) {
                    toast.error(`بيانات المشرف مسجلة مسبقاً: ${formData.moderatorData.email || formData.moderatorData.phone}`);
                    setIsSubmitting(false);
                    return;
                }
            } catch (err) {
                console.error(err);
                toast.error('فشل في التحقق من البيانات');
                setIsSubmitting(false);
                return;
            }
            setIsSubmitting(false);
        }

        if (currentStep < 8) {
            setCurrentStep(prev => prev + 1);
            window.scrollTo(0, 0);
        } else {
            handleSubmit();
        }
    };

    const handleBack = () => {
        if (currentStep > 1) {
            setCurrentStep(prev => prev - 1);
            window.scrollTo(0, 0);
        }
    };

    const handleSubmit = async () => {
        setIsSubmitting(true);
        try {
            const response = await fetch('/api/sales/onboarding', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                credentials: 'include',
                body: JSON.stringify(formData),
            });

            const result = await response.json();

            if (!response.ok) throw new Error(result.message);

            toast.success('تم إنشاء المدرسة والحسابات بنجاح!');
            // Navigate to success page or dashboard
            setTimeout(() => {
                router.push('/pages/admission/me');
            }, 2000);
        } catch (error) {
            toast.error(error.message || 'حدث خطأ أثناء الإنشاء');
        } finally {
            setIsSubmitting(false);
        }
    };

    const validateStep = () => {
        if (currentStep === 1) {
            const sd = formData.schoolData;
            return (
                sd.name &&
                sd.nameEn &&
                sd.educationSystemId &&
                sd.location?.governorate &&
                sd.location?.educationalAdministration
            );
        }
        if (currentStep === 2) {
            const sd = formData.schoolData;
            // Validate that at least one stage is selected in the new structure format
            const activeStages = Object.values(sd.selectedStructure?.stages || {}).filter(s => s.active);
            return activeStages.length > 0;
        }
        if (currentStep === 3) {
            // Former Step 4 (School Details) is now Step 3
            // Example validation: fees and admission fee should be filled if required
            const sd = formData.schoolData;
            // Add specific validation logic for "Required Data" if needed, e.g.
            // return sd.feesDetails?.admissionFee !== ''; 
            return true;
        }
        if (currentStep === 4) {
            // Working Hours - No strict validation required
            return true;
        }
        if (currentStep === 5) {
            // Facilities - No strict validation required
            return true;
        }
        if (currentStep === 6) {
            // Former Step 3 (Accounts) is now Step 6
            const { ownerData, moderatorData } = formData;
            const isOwnerValid = ownerData.name && ownerData.email && ownerData.phone && ownerData.password;
            const isModeratorValid = moderatorData.name && moderatorData.email && moderatorData.phone && moderatorData.password;
            return isOwnerValid && isModeratorValid;
        }
        return true;
    };

    const isNextDisabled = isSubmitting || !validateStep();

    return (
        <div className="min-h-screen bg-gray-50/50 p-6 md:p-12 direction-rtl" dir="rtl">
            {/* Stylesheets for Icons */}
            <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" />
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/boxicons@latest/css/boxicons.min.css" />

            <div className="max-w-5xl mx-auto space-y-8">
                {/* ... existing jsx ... */}

                {/* Header */}
                <div className="text-center space-y-2">
                    <h1 className="text-3xl font-black text-gray-900 tracking-tight">إعداد مدرسة جديدة</h1>
                    <p className="text-gray-500 text-lg">لوحة تحكم المبيعات - معالج الإعداد السريع</p>
                </div>

                {/* Stepper */}
                <div className="relative">
                    <div className="absolute top-1/2 left-0 w-full h-1 bg-gray-200 -z-0 rounded-full"></div>
                    <div
                        className="absolute top-1/2 right-0 h-1 bg-gradient-to-l from-blue-600 to-indigo-600 -z-0 rounded-full transition-all duration-500 ease-in-out"
                        style={{ width: `${((currentStep - 1) / (steps.length - 1)) * 100}%` }}
                    ></div>

                    <div className="flex justify-between items-center relative z-10 w-full">
                        {steps.map((step) => {
                            const isActive = step.id === currentStep;
                            const isCompleted = step.id < currentStep;
                            const Icon = step.icon;

                            return (
                                <div key={step.id} className="flex flex-col items-center gap-3">
                                    <div
                                        className={`w-14 h-14 rounded-2xl flex items-center justify-center transition-all duration-300 shadow-xl border-4 ${isActive
                                            ? 'bg-blue-600 border-white ring-4 ring-blue-100 text-white scale-110'
                                            : isCompleted
                                                ? 'bg-green-500 border-white text-white'
                                                : 'bg-white border-white text-gray-300'
                                            }`}
                                    >
                                        {isCompleted ? <FiCheck size={24} /> : <Icon size={24} />}
                                    </div>
                                    <span className={`text-xs font-bold transition-colors duration-300 ${isActive ? 'text-blue-700' : isCompleted ? 'text-green-600' : 'text-gray-400'}`}>
                                        {step.label}
                                    </span>
                                </div>
                            );
                        })}
                    </div>
                </div>

                {/* Content Card */}
                <div className="bg-white rounded-[2rem] shadow-2xl border border-gray-100 p-8 min-h-[400px] animate-in fade-in slide-in-from-bottom-4 duration-500">

                    {currentStep === 1 && <StepSchoolData data={formData.schoolData} updateData={(d) => updateFormData('schoolData', d)} />}
                    {currentStep === 2 && <StepAcademicSettings data={formData.schoolData} updateData={(d) => updateFormData('schoolData', d)} />}
                    {currentStep === 3 && <StepSchoolDetails data={formData.schoolData} updateData={(d) => updateFormData('schoolData', d)} />}
                    {currentStep === 4 && <StepWorkingHours data={formData.schoolData} updateData={(d) => updateFormData('schoolData', d)} />}
                    {currentStep === 5 && <StepFacilities data={formData.schoolData} updateData={(d) => updateFormData('schoolData', d)} />}
                    {currentStep === 6 && <StepAccounts data={{ owner: formData.ownerData, moderator: formData.moderatorData, customUsers: formData.customUsers }} updateData={(section, d) => updateFormData(section, d)} />}
                    {currentStep === 7 && <StepSiteSetup data={formData.configData} updateData={(d) => updateFormData('configData', d)} />}
                    {currentStep === 8 && <StepReview data={formData} />}

                </div>

                {/* Footer Navigation */}
                <div className="flex items-center justify-between pt-4">
                    <button
                        onClick={handleBack}
                        disabled={currentStep === 1 || isSubmitting}
                        className={`flex items-center gap-2 px-8 py-4 rounded-xl font-bold text-gray-600 transition-all ${currentStep === 1 ? 'opacity-0 cursor-default' : 'hover:bg-gray-200 active:scale-95'
                            }`}
                    >
                        <FiChevronRight /> السابق
                    </button>

                    <button
                        onClick={handleNext}
                        disabled={isNextDisabled}
                        className={`flex items-center gap-3 px-10 py-4 rounded-2xl font-bold text-white shadow-xl transition-all transform ${isNextDisabled ? 'opacity-50 cursor-not-allowed bg-gray-400' :
                            currentStep === 8
                                ? 'bg-gradient-to-l from-green-500 to-emerald-600 hover:shadow-green-500/30 hover:scale-105 active:scale-95'
                                : 'bg-gradient-to-l from-blue-600 to-indigo-700 hover:shadow-blue-600/30 hover:scale-105 active:scale-95'
                            }`}
                    >
                        {isSubmitting ? 'جاري الحفظ...' : currentStep === 8 ? 'إتمام وإنشاء' : 'التالي'}
                        {!isSubmitting && (currentStep === 8 ? <FiCheck size={20} /> : <FiChevronLeft size={20} />)}
                    </button>

                </div>

            </div>
        </div>
    );
}
