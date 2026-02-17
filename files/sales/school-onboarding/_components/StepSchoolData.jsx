import { useState, useEffect } from 'react';
import { FiBriefcase, FiMapPin, FiBook, FiCheck, FiUsers, FiUser, FiHeart, FiShield, FiMap, FiGlobe } from 'react-icons/fi';
import egyptData from '@/data/egypt-data.json';
import { SCHOOL_TYPES, GENDER_POLICIES, RELIGION_TYPES, SPECIAL_NEEDS_TYPES } from '@/lib/constants';
import dynamic from 'next/dynamic';

const MapPicker = dynamic(() => import('./MapPicker'), {
    ssr: false,
    loading: () => <div className="h-[300px] w-full bg-gray-100 animate-pulse rounded-xl flex items-center justify-center border-2 border-dashed border-slate-200 text-slate-400 font-bold text-center p-4">
        جاري تحميل الخريطة...<br />يرجى الانتظار
    </div>
});

export default function StepSchoolData({ data, updateData }) {
    const [systems, setSystems] = useState([]);
    const [tracks, setTracks] = useState([]);
    const [loading, setLoading] = useState(true);
    const [selectedGovId, setSelectedGovId] = useState(() => {
        // Find ID by name if already set
        if (data.location?.governorate) {
            const gov = egyptData.governorates.find(g => g.nameAr === data.location.governorate);
            return gov ? gov.id : '';
        }
        return '';
    });

    useEffect(() => {
        const fetchSystems = async () => {
            try {
                const res = await fetch('/api/public/education-systems');
                const result = await res.json();
                if (result.success) {
                    setSystems(result.systems);
                }
            } catch (error) {
                console.error("Failed to load education systems", error);
            } finally {
                setLoading(false);
            }
        };
        fetchSystems();
    }, []);

    // Filter systems based on school type
    const [filteredSystems, setFilteredSystems] = useState([]);

    useEffect(() => {
        if (!data.type) {
            setFilteredSystems(systems);
        } else {
            setFilteredSystems(systems.filter(s => s.type === data.type || !s.type)); // Show matching or universal systems
        }
    }, [data.type, systems]);

    // Reset system if current one is not in filtered list
    useEffect(() => {
        if (data.type && data.educationSystemId && filteredSystems.length > 0) {
            const isAvailable = filteredSystems.some(s => s.id === data.educationSystemId);
            if (!isAvailable) {
                updateData({
                    educationSystemId: '',
                    educationTrackId: '',
                    selectedStructure: { stages: {}, classes: {}, subjects: {} }
                });
            }
        }
    }, [data.type, filteredSystems]);

    // Update tracks when system changes
    useEffect(() => {
        if (data.educationSystemId && systems.length > 0) {
            const selectedSystem = systems.find(s => s.id === data.educationSystemId);
            if (selectedSystem) {
                const systemTracks = selectedSystem.tracks || [];
                setTracks(systemTracks);

                // Auto-select if ONLY ONE track exists and none selected
                if (systemTracks.length === 1 && !data.educationTrackId) {
                    updateData({ educationTrackId: systemTracks[0].id });
                }
            } else {
                setTracks([]);
            }
        }
    }, [data.educationSystemId, systems]);



    return (
        <div className="space-y-6 animate-in fade-in slide-in-from-right-8 duration-500">
            <div className="flex items-center gap-4 mb-6">
                <div className="p-3 bg-blue-100 text-blue-600 rounded-xl">
                    <FiBriefcase size={24} />
                </div>
                <div>
                    <h2 className="text-xl font-bold text-gray-800">بيانات المدرسة الأساسية</h2>
                    <p className="text-gray-500 text-sm">أدخل المعلومات التعريفية للمدرسة</p>
                </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                    <label className="block text-sm font-bold text-gray-700 mb-2">اسم المدرسة باللغة العربية</label>
                    <input
                        type="text"
                        value={data.name}
                        onChange={(e) => updateData({ name: e.target.value })}
                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-4 focus:ring-blue-50/50 outline-none transition-all font-bold text-lg"
                        placeholder="مثال: مدارس النيل المصرية الدولية"
                    />
                </div>

                <div>
                    <label className="block text-sm font-bold text-gray-700 mb-2">اسم المدرسة باللغة الانجليزية</label>
                    <input
                        type="text"
                        value={data.nameEn || ''}
                        onChange={(e) => updateData({ nameEn: e.target.value })}
                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-4 focus:ring-blue-50/50 outline-none transition-all font-bold text-lg text-left"
                        placeholder="Ex: Nile Egyptian International Schools"
                        dir="ltr"
                    />
                </div>

                <div>
                    <label className="block text-sm font-bold text-gray-700 mb-2">الاسم المختصر</label>
                    <input
                        type="text"
                        value={data.shortName || ''}
                        onChange={(e) => updateData({ shortName: e.target.value })}
                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 outline-none transition-all font-bold"
                        placeholder="Ex: NES"
                        dir="ltr"
                    />
                </div>

                <div>
                    <label className="block text-sm font-bold text-gray-700 mb-2">نوع المدرسة (حسب جهة الإشراف والملكية)</label>
                    <select
                        value={data.type}
                        onChange={(e) => updateData({ type: e.target.value })}
                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 outline-none bg-white font-bold"
                    >
                        <option value="" disabled>اختر نوع المدرسة</option>
                        {SCHOOL_TYPES.map(type => (
                            <option key={type.id} value={type.id}>{type.label}</option>
                        ))}
                    </select>
                </div>

                <div className="md:col-span-2 bg-slate-50/50 p-6 rounded-2xl border border-slate-200/60 shadow-sm space-y-8">
                    <div className="flex flex-wrap items-end gap-x-12 gap-y-6">
                        {/* Gender Segmented Control */}
                        <div className="space-y-3">
                            <label className="text-sm font-bold text-slate-600 flex items-center gap-2">
                                <FiUsers className="text-blue-500" /> سياسة القبول حسب جنس الطالب
                            </label>
                            <div className="flex bg-white p-1 rounded-xl border border-slate-200 w-fit">
                                {GENDER_POLICIES.map((option) => (
                                    <button
                                        key={option.id}
                                        type="button"
                                        onClick={() => updateData({ genderPolicy: option.id })}
                                        className={`px-6 py-2 rounded-lg text-sm font-bold transition-all flex items-center gap-2 ${(data.genderPolicy || 'Mixed') === option.id
                                            ? 'bg-blue-600 text-white shadow-md'
                                            : 'text-slate-500 hover:bg-slate-50'
                                            }`}
                                    >
                                        {option.label}
                                    </button>
                                ))}
                            </div>
                        </div>

                        {/* Religion Type selection */}
                        <div className="space-y-3">
                            <label className="text-sm font-bold text-slate-600 flex items-center gap-2">
                                <FiShield className="text-blue-500" /> سياسة القبول حسب ديانة الطالب
                            </label>
                            <div className="flex bg-white p-1 rounded-xl border border-slate-200 w-fit shadow-sm">
                                {RELIGION_TYPES.map((type) => (
                                    <button
                                        key={type.id}
                                        type="button"
                                        onClick={() => updateData({
                                            religionType: type.id,
                                            isReligious: type.id !== 'None'
                                        })}
                                        className={`px-5 py-2 rounded-lg text-sm font-bold transition-all ${(data.religionType || 'None') === type.id
                                            ? 'bg-blue-600 text-white shadow-md shadow-blue-100'
                                            : 'text-slate-400 hover:bg-slate-50'
                                            }`}
                                    >
                                        {type.label}
                                    </button>
                                ))}
                            </div>
                        </div>

                        {/* Special Needs selection - Direct Choice */}
                        <div className="space-y-3">
                            <label className="text-sm font-bold text-slate-600 flex items-center gap-2">
                                <FiHeart className="text-blue-500" /> سياسة قبول ذوي الاحتياجات الخاصة
                            </label>
                            <div className="flex bg-white p-1 rounded-xl border border-slate-200 w-fit shadow-sm">
                                {SPECIAL_NEEDS_TYPES.map((type) => {
                                    const isSelected = (data.specialNeedsType || 'لا يوجد') === type.label;
                                    return (
                                        <button
                                            key={type.id}
                                            type="button"
                                            onClick={() => updateData({
                                                specialNeedsType: type.label,
                                                supportsSpecialNeeds: type.id !== 'None'
                                            })}
                                            className={`px-5 py-2 rounded-lg text-sm font-bold transition-all ${isSelected
                                                ? 'bg-blue-600 text-white shadow-md shadow-blue-100'
                                                : 'text-slate-400 hover:bg-slate-50'
                                                }`}
                                        >
                                            {type.label}
                                        </button>
                                    );
                                })}
                            </div>
                        </div>
                    </div>
                    {/* 
                    <div className="pt-6 border-t border-slate-200/60 flex items-center justify-between">
                        <div className="flex items-center gap-2 text-xs font-bold text-slate-400 bg-slate-100/50 px-3 py-1 rounded-full">
                            <FiCheck size={12} className="text-emerald-500" />
                            سياسات القبول يتم تحديثها فورياً
                        </div>
                        <div className="text-xs text-slate-400 italic">
                            * يرجى التأكد من توافق السياسات المختارة مع لوائح المدرسة.
                        </div>
                    </div> */}
                </div>

                {/* Education System (NT) */}
                <div>
                    <label className="block text-sm font-bold text-gray-700 mb-2">النظام التعليمى</label>
                    {loading ? (
                        <div className="w-full h-[50px] bg-gray-100 rounded-xl animate-pulse"></div>
                    ) : (
                        <select
                            value={data.educationSystemId || ''}
                            onChange={(e) => {
                                const sysId = e.target.value;
                                updateData({
                                    educationSystemId: sysId,
                                    educationTrackId: '', // Reset track
                                    selectedStructure: { stages: {}, classes: {}, subjects: {} } // Reset structure
                                });
                            }}
                            className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-4 focus:ring-blue-50/50 outline-none bg-white font-bold transition-all"
                        >
                            <option value="">
                                {!data.type ? "اختر نوع المدرسة أولاً" : "اختر نظام التعليم"}
                            </option>
                            {filteredSystems.map(sys => (
                                <option key={sys.id} value={sys.id}>{sys.name}</option>
                            ))}
                        </select>
                    )}
                </div>

                {/* Education Track (MT) */}
                <div>
                    <label className="block text-sm font-bold text-gray-700 mb-2">المسار التعليمى</label>
                    <select
                        value={data.educationTrackId || ''}
                        onChange={(e) => updateData({ educationTrackId: e.target.value })}
                        disabled={!data.educationSystemId || tracks.length === 0}
                        className={`w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-4 focus:ring-blue-50/50 outline-none transition-all font-bold ${(!data.educationSystemId || tracks.length === 0) ? 'bg-gray-100 text-gray-400 cursor-not-allowed' : 'bg-white'}`}
                    >
                        <option value="">
                            {!data.educationSystemId
                                ? "برجاء اختيار نظام التعليم أولاً"
                                : tracks.length === 0
                                    ? "لا توجد مسارات لهذا النظام"
                                    : "اختر المسار (اختياري)"}
                        </option>
                        {tracks.map(track => (
                            <option key={track.id} value={track.id}>{track.name}</option>
                        ))}
                    </select>
                </div>

                <div className="md:col-span-2 grid grid-cols-2 gap-4">
                    <div>
                        <label className="block text-sm font-bold text-gray-700 mb-2">المحافظة</label>
                        <select
                            value={selectedGovId}
                            onChange={(e) => {
                                const govId = e.target.value;
                                setSelectedGovId(govId);
                                const gov = egyptData.governorates.find(g => g.id === govId);
                                updateData({
                                    location: {
                                        ...data.location,
                                        governorate: gov ? gov.nameAr : '',
                                        educationalAdministration: '' // Reset admin when gov changes
                                    }
                                });
                            }}
                            className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-4 focus:ring-blue-50/50 outline-none bg-white font-bold transition-all"
                        >
                            <option value="">اختر المحافظة</option>
                            {egyptData.governorates.map(gov => (
                                <option key={gov.id} value={gov.id}>{gov.nameAr}</option>
                            ))}
                        </select>
                    </div>
                    <div>
                        <label className="block text-sm font-bold text-gray-700 mb-2">الإدارة التعليمة</label>
                        <select
                            value={data.location?.educationalAdministration || ''}
                            disabled={!selectedGovId}
                            onChange={(e) => updateData({ location: { ...data.location, educationalAdministration: e.target.value } })}
                            className={`w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 focus:ring-4 focus:ring-blue-50/50 outline-none transition-all font-bold ${!selectedGovId ? 'bg-gray-50 cursor-not-allowed' : 'bg-white'}`}
                        >
                            <option value="">
                                {!selectedGovId ? "اختر المحافظة أولاً" : "اختر الإدارة التعليمة"}
                            </option>
                            {selectedGovId && egyptData.administrations[selectedGovId]?.map(admin => (
                                <option key={admin.id} value={admin.nameAr}>{admin.nameAr}</option>
                            ))}
                        </select>
                    </div>
                </div>
                <div className="md:col-span-2 space-y-4">
                    <div>
                        <label className="block text-sm font-bold text-gray-700 mb-2">العنوان التفصيلي</label>
                        <textarea
                            value={data.location?.detailedAddress || ''}
                            onChange={(e) => updateData({
                                location: { ...data.location, detailedAddress: e.target.value }
                            })}
                            rows={2}
                            className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-blue-500 outline-none bg-white font-bold resize-none"
                            placeholder="مثال: شارع التسعين الشمالي، بجوار الجامعة الأمريكية، القاهرة الجديدة"
                        />
                    </div>

                    <div className="space-y-2">
                        <label className="block text-sm font-bold text-gray-700 flex items-center gap-2">
                            <FiMap className="text-blue-500" /> الموقع على الخريطة (اللوكيشن)
                        </label>
                        <MapPicker
                            lat={data.location?.coordinates?.lat}
                            lng={data.location?.coordinates?.lng}
                            onLocationChange={(coords, address) => updateData({
                                location: {
                                    ...data.location,
                                    coordinates: coords,
                                    detailedAddress: address || data.location?.detailedAddress || ''
                                }
                            })}
                        />
                        <p className="text-[10px] text-slate-400 italic">
                            * يمكنك النقر على الخريطة لتحديد موقع المدرسة بدقة أو استخدام زر تحديد الموقع الحالي.
                        </p>
                    </div>
                </div>

            </div>

            {/* Helper import for FiCheck since I used it */}
            <div className="hidden">
                {/* Just ensuring icons are imported if not already. I used FiCheck. Let me check imports. */}
            </div>
        </div>
    );
}
