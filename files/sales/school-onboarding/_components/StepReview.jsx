'use client';
import { useState, useEffect } from 'react';
import { FiFlag, FiLayers, FiDollarSign, FiActivity, FiCheckCircle } from 'react-icons/fi';
import { SCHOOL_TYPES } from '@/lib/constants';

export default function StepReview({ data }) {
    const s = data.schoolData.selectedStructure || { stages: {}, classes: {}, subjects: {} };
    const financials = data.schoolData.financials || {};
    const installments = data.schoolData.installments || {};
    const facilities = data.schoolData.facilities || [];

    const [facilitiesMap, setFacilitiesMap] = useState({});
    const [systemInfo, setSystemInfo] = useState({ name: '', track: '' });

    useEffect(() => {
        if (facilities.length > 0) {
            fetch('/api/admin/facilities')
                .then(res => res.json())
                .then(result => {
                    if (result.success && Array.isArray(result.facilities)) {
                        const map = {};
                        result.facilities.forEach(f => map[f.id] = f.name);
                        setFacilitiesMap(map);
                    }
                })
                .catch(err => console.error(err));
        }
    }, [facilities.length]);

    useEffect(() => {
        if (data.schoolData.educationSystemId) {
            fetch('/api/public/education-systems')
                .then(res => res.json())
                .then(result => {
                    if (result.success) {
                        const sys = result.systems.find(s => s.id === data.schoolData.educationSystemId);
                        if (sys) {
                            let trackName = '';
                            if (data.schoolData.educationTrackId && sys.tracks) {
                                const trk = sys.tracks.find(t => t.id === data.schoolData.educationTrackId);
                                if (trk) trackName = trk.name;
                            }
                            setSystemInfo({ name: sys.name, track: trackName });
                        }
                    }
                })
                .catch(err => console.error(err));
        }
    }, [data.schoolData.educationSystemId, data.schoolData.educationTrackId]);

    const getActiveCount = (obj) => Object.values(obj || {}).filter(x => x && x.active).length;

    // Get Arabic label for type
    const schoolTypeLabel = SCHOOL_TYPES.find(t => t.id === data.schoolData.type)?.label || data.schoolData.type;

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-right-8 duration-500">
            {/* Header */}
            <div className="flex items-center gap-4 mb-2">
                <div className="p-3 bg-green-600 text-white rounded-xl shadow-lg shadow-green-200">
                    <FiFlag size={24} />
                </div>
                <div>
                    <h2 className="text-xl font-bold text-gray-800">مراجعة وإنهاء</h2>
                    <p className="text-gray-500 text-sm">تأكد من صحة البيانات قبل الإنشاء النهائي</p>
                </div>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">

                {/* 1. School Basic Info */}
                <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm space-y-4">
                    <h3 className="text-sm font-bold text-gray-400 uppercase tracking-wider border-b border-gray-100 pb-2">بيانات المدرسة</h3>
                    <div className="grid grid-cols-2 gap-y-4 gap-x-2 text-sm">
                        <div className="col-span-2">
                            <span className="block text-xs text-gray-400">الاسم</span>
                            <span className="font-bold text-gray-800 text-lg">{data.schoolData.name || '-'}</span>
                        </div>
                        <div>
                            <span className="block text-xs text-gray-400">النوع</span>
                            <span className="font-bold text-gray-800">{schoolTypeLabel}</span>
                        </div>
                        <div>
                            <span className="block text-xs text-gray-400">نظام التعليم</span>
                            <div className="flex flex-col">
                                <span className="font-bold text-blue-600">{systemInfo.name || data.schoolData.educationSystem || '...'}</span>
                                {systemInfo.track && (
                                    <span className="text-[10px] text-blue-600 bg-blue-50 px-1.5 py-0.5 rounded w-fit mt-1 font-bold">
                                        مسار: {systemInfo.track}
                                    </span>
                                )}
                            </div>
                        </div>
                        <div className="col-span-2">
                            <span className="block text-xs text-gray-400">الموقع</span>
                            <span className="font-bold text-gray-800">
                                {[
                                    data.schoolData.location?.governorate,
                                    data.schoolData.location?.educationalAdministration,
                                    data.schoolData.location?.address
                                ].filter(Boolean).join(' - ')}
                            </span>
                        </div>
                        <div>
                            <span className="block text-xs text-gray-400">الجنس</span>
                            <span className="font-bold text-gray-800">{data.schoolData.gender || 'Mixed'}</span>
                        </div>
                    </div>
                </div>

                {/* 2. Accounts */}
                <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm space-y-4">
                    <h3 className="text-sm font-bold text-gray-400 uppercase tracking-wider border-b border-gray-100 pb-2">الحسابات</h3>
                    <div className="space-y-4">
                        <div className="flex items-center gap-3 p-2 bg-blue-50 rounded-lg">
                            <div className="w-8 h-8 rounded-full bg-blue-200 flex items-center justify-center text-blue-700 font-bold text-xs">O</div>
                            <div>
                                <p className="text-sm font-bold text-gray-800">{data.ownerData.name || 'المالك'}</p>
                                <p className="text-xs text-gray-500">{data.ownerData.phone || data.ownerData.email}</p>
                                <span className="text-[10px] text-blue-600 bg-blue-100 px-1 rounded">Owner</span>
                            </div>
                        </div>
                        <div className="flex items-center gap-3 p-2 bg-purple-50 rounded-lg">
                            <div className="w-8 h-8 rounded-full bg-purple-200 flex items-center justify-center text-purple-700 font-bold text-xs">M</div>
                            <div>
                                <p className="text-sm font-bold text-gray-800">{data.moderatorData.name || 'المشرف'}</p>
                                <p className="text-xs text-gray-500">{data.moderatorData.phone || data.moderatorData.email}</p>
                                <span className="text-[10px] text-purple-600 bg-purple-100 px-1 rounded">Moderator</span>
                            </div>
                        </div>
                        {data.customUsers?.length > 0 && (
                            <div className="text-xs text-gray-500 pt-1 border-t border-gray-100 mt-2">
                                + {data.customUsers.length} مستخدمين إضافيين
                            </div>
                        )}
                    </div>
                </div>

                {/* 3. Academic Structure */}
                <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm space-y-4 relative overflow-hidden">
                    <div className="absolute top-0 right-0 w-24 h-24 bg-indigo-50 rounded-bl-full -mr-6 -mt-6" />
                    <h3 className="text-sm font-bold text-gray-400 uppercase tracking-wider border-b border-gray-100 pb-2 relative z-10 flex items-center gap-2">
                        <FiLayers /> الهيكل الأكاديمي
                    </h3>

                    <div className="grid grid-cols-2 gap-4 text-center relative z-10 mt-4">
                        <div className="bg-gray-50 p-3 rounded-xl border border-gray-100 transition-transform hover:scale-105">
                            <span className="block text-3xl font-black text-indigo-600 mb-1">{getActiveCount(s.stages)}</span>
                            <span className="text-xs font-bold text-gray-500">مراحل تعليمية</span>
                        </div>
                        <div className="bg-gray-50 p-3 rounded-xl border border-gray-100 transition-transform hover:scale-105">
                            <span className="block text-3xl font-black text-indigo-600 mb-1">{getActiveCount(s.classes)}</span>
                            <span className="text-xs font-bold text-gray-500">صفوف دراسية</span>
                        </div>
                    </div>
                    {getActiveCount(s.stages) === 0 && (
                        <p className="text-xs text-red-500 bg-red-50 p-2 rounded border border-red-100 mt-2">
                            تنويـه: لم يتم تفعيل أي مراحل أو صفوف. يرجى المراجعة.
                        </p>
                    )}
                </div>

                {/* 4. Financials */}
                <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm space-y-4">
                    <h3 className="text-sm font-bold text-gray-400 uppercase tracking-wider border-b border-gray-100 pb-2 flex items-center gap-2">
                        <FiDollarSign /> الإعدادات المالية
                    </h3>
                    <div className="text-sm space-y-3">
                        <div className="flex justify-between items-center border-b border-gray-50 pb-2">
                            <span className="text-gray-600 text-xs">رسوم التسجيل</span>
                            <span className="font-bold text-emerald-600">{financials.registrationFees || 0} ج.م</span>
                        </div>
                        <div className="flex justify-between items-center border-b border-gray-50 pb-2">
                            <span className="text-gray-600 text-xs">رسوم الزي</span>
                            <span className="font-bold text-emerald-600">{financials.uniformFees || 0} ج.م</span>
                        </div>
                        <div className="flex justify-between items-center border-b border-gray-50 pb-2">
                            <span className="text-gray-600 text-xs">اشتراك الباص</span>
                            <span className="font-bold text-gray-800">{financials.busFeesMin || 0} - {financials.busFeesMax || 0} ج.م</span>
                        </div>
                        <div className="pt-1">
                            <div className="flex justify-between items-center">
                                <span className="text-xs text-gray-400">نظام التقسيط</span>
                                {installments.allowed ? (
                                    <span className="bg-blue-100 text-blue-700 px-2 py-0.5 rounded text-xs font-bold">
                                        مفعل ({installments.installmentsCount || 0} أقساط)
                                    </span>
                                ) : (
                                    <span className="bg-gray-100 text-gray-500 px-2 py-0.5 rounded text-xs">غير مفعل</span>
                                )}
                            </div>
                        </div>
                    </div>
                </div>

                {/* 5. Facilities & Config */}
                <div className="bg-white p-5 rounded-2xl border border-gray-100 shadow-sm space-y-4 lg:col-span-2">
                    <div className="flex flex-col md:flex-row justify-between items-start gap-4">
                        <div className="flex-1">
                            <h3 className="text-sm font-bold text-gray-400 uppercase tracking-wider mb-3 flex items-center gap-2">
                                <FiActivity /> المرافق المختارة
                            </h3>
                            <div className="flex flex-wrap gap-2 text-xs">
                                {facilities.length > 0 ? facilities.map((f, i) => (
                                    <span key={i} className="bg-orange-50 text-orange-700 px-3 py-1.5 rounded-lg border border-orange-100 font-medium whitespace-nowrap">
                                        🛠 {facilitiesMap[f.facilityId] || f.facilityId} | {f.value}
                                    </span>
                                )) : <span className="text-gray-400 italic">لا توجد مرافق مختارة</span>}
                            </div>
                        </div>
                        <div className="w-full md:w-auto p-4 bg-gray-50 rounded-xl border border-gray-200 text-center">
                            <h4 className="text-xs font-bold text-gray-500 mb-2">حالة المدرسة</h4>
                            <div className="space-y-2">
                                <span className={`block px-4 py-1.5 rounded-lg text-xs font-bold ${data.configData.approved ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-700'}`}>
                                    {data.configData.approved ? 'Approved ✓' : 'Pending Review'}
                                </span>
                                <span className={`block px-4 py-1.5 rounded-lg text-xs font-bold ${data.configData.showInSearch ? 'bg-blue-100 text-blue-700' : 'bg-gray-200 text-gray-600'}`}>
                                    {data.configData.showInSearch ? 'Visible in Search' : 'Hidden'}
                                </span>
                            </div>
                        </div>
                    </div>
                </div>

            </div>

            <div className="flex items-start gap-4 p-4 bg-yellow-50 text-yellow-800 rounded-xl text-sm border border-yellow-200 shadow-sm">
                <FiCheckCircle className="mt-1 shrink-0 text-yellow-600" size={20} />
                <div>
                    <p className="font-bold mb-1">تأكيد نهائي</p>
                    <p>
                        بمجرد النقر على "إنشاء"، سيتم:
                        <br />1. إنشاء سجل المدرسة في قاعدة البيانات.
                        <br />2. إنشاء هيكل النظام التعليمي (Active Structure) في جداول (Stages, Grades, Classes, Subjects).
                        <br />3. ربط حسابات المالك والمشرف بالمدرسة.
                    </p>
                </div>
            </div>
        </div>
    );
}
