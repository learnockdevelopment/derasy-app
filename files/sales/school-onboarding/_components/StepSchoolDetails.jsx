import { useState, useEffect } from 'react';
import { FiDatabase, FiDollarSign, FiEye, FiX, FiCalendar } from 'react-icons/fi';

export default function StepSchoolDetails({ data, updateData }) {

    // Helper to perform multiple updates for classes
    const updateClassFees = (classId, fee) => {
        const s = JSON.parse(JSON.stringify(data.selectedStructure || { stages: {}, classes: {}, subjects: {} }));
        if (!s.classes[classId]) return;

        s.classes[classId] = { ...s.classes[classId], fees: parseFloat(fee) || 0 };
        updateData({ selectedStructure: s });
    };

    const updateClassDiscount = (classId, discount) => {
        const s = JSON.parse(JSON.stringify(data.selectedStructure || { stages: {}, classes: {}, subjects: {} }));
        if (!s.classes[classId]) return;

        s.classes[classId] = { ...s.classes[classId], discount: parseFloat(discount) || 0 };
        updateData({ selectedStructure: s });
    };

    const handleInstallmentChange = (type, value, index = null) => {
        const inst = data.installments || {};
        // Use current values unless updating them
        let dpVal = type === 'dp' ? value : (inst.downPayment || 0);
        let countVal = type === 'count' ? value : (inst.installmentsCount || 0);

        let dp = parseFloat(dpVal) || 0;
        let count = parseInt(countVal) || 0;

        // Limit count to reasonable number (e.g. 24) to prevent loop freeze
        if (count > 24) count = 24;

        const newDates = { ...(inst.dates || {}) };

        if (type === 'rate' && index !== null) {
            // Custom rate change: Update THIS rate, and redistribute remaining among SUBSEQUENT rates.
            const rateVal = parseFloat(value) || 0;
            newDates[`rate_${index}`] = value;

            // Calculate used amount (Down Payment + All rates up to current index)
            let used = dp;
            for (let i = 0; i < index; i++) {
                used += (parseFloat(newDates[`rate_${i}`]) || 0);
            }
            // Add current new value
            used += rateVal;

            let remaining = 100 - used;
            let subsequentCount = count - (index + 1);

            if (subsequentCount > 0) {
                // Distribute remaining equally among subsequent installments
                const perSubsequent = Math.max(0, remaining / subsequentCount);
                for (let i = index + 1; i < count; i++) {
                    newDates[`rate_${i}`] = parseFloat(perSubsequent.toFixed(2));
                }
            }
        } else {
            // Recalculate all equally based on remaining (100 - DP)
            // This happens when Down Payment or Count changes
            let remaining = 100 - dp;
            if (count > 0) {
                const perInst = Math.max(0, remaining / count);
                for (let i = 0; i < count; i++) {
                    // Reset all rates to equal distribution
                    newDates[`rate_${i}`] = parseFloat(perInst.toFixed(2));
                }
            }
        }

        updateData({
            installments: {
                ...inst,
                downPayment: dpVal,
                installmentsCount: countVal,
                dates: newDates
            }
        });
    };

    // Facilities Logic Removed
    const [previewClass, setPreviewClass] = useState(null);


    // We need the system structure to render the labels (names of stages/grades).
    // Let's reuse the fetch logic.
    const [structure, setStructure] = useState(null);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        if (data.educationSystemId) {
            const fetchStructure = async () => {
                setLoading(true);
                try {
                    const res = await fetch(`/api/admin/education-systems/${data.educationSystemId}`);
                    const result = await res.json();
                    if (result.success) {
                        setStructure(result.system);
                    }
                } catch (e) {
                    console.error("Failed to fetch structure", e);
                } finally {
                    setLoading(false);
                }
            };
            fetchStructure();
        }
    }, [data.educationSystemId]);

    const s = data.selectedStructure || { stages: {}, classes: {}, subjects: {} };

    return (
        <div className="space-y-6 animate-in fade-in slide-in-from-right-8 duration-500">
            <div className="flex items-center gap-4 mb-6">
                <div className="p-3 bg-green-100 text-green-600 rounded-xl">
                    <FiDatabase size={24} />
                </div>
                <div>
                    <h2 className="text-xl font-bold text-gray-800">تفاصيل إضافية مطلوبة (المالية)</h2>
                    <p className="text-gray-500 text-sm">تحديد مصاريف الصفوف الدراسية</p>
                </div>
            </div>

            {/* Installment Plan Configuration */}
            <div className="bg-blue-50/50 border border-blue-100 rounded-2xl p-5 mb-6">
                <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-3">
                        <div className={`p-2 rounded-lg ${data.installments?.allowed ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-500'}`}>
                            <FiDollarSign />
                        </div>
                        <div>
                            <h3 className="font-bold text-gray-800">نظام التقسيط (Installments)</h3>
                            <p className="text-xs text-gray-500">هل تتيح المدرسة دفع المصروفات على أقساط؟</p>
                        </div>
                    </div>
                    <label className="relative inline-flex items-center cursor-pointer">
                        <input
                            type="checkbox"
                            className="sr-only peer"
                            checked={data.installments?.allowed || false}
                            onChange={(e) => updateData({ installments: { ...(data.installments || {}), allowed: e.target.checked } })}
                        />
                        <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                    </label>
                </div>

                {data.installments?.allowed && (
                    <div className="space-y-4 animate-in fade-in slide-in-from-top-2 duration-300 border-t border-blue-100 pt-4 mt-2">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label className="block text-xs font-bold text-gray-600 mb-1">نسبة الدفعة المقدمة (Down Payment %)</label>
                                <div className="relative">
                                    <input
                                        type="number"
                                        className="w-full pl-3 pr-8 py-2 rounded-xl border border-blue-200 focus:ring-2 focus:ring-blue-500 outline-none text-sm"
                                        placeholder="e.g. 20"
                                        value={data.installments?.downPayment || ''}
                                        onChange={(e) => handleInstallmentChange('dp', e.target.value)}
                                    />
                                    <span className="absolute right-3 top-2 text-gray-400 text-xs font-bold">%</span>
                                </div>
                            </div>
                            <div>
                                <label className="block text-xs font-bold text-gray-600 mb-1">عدد الأقساط (Number of Installments)</label>
                                <input
                                    type="number"
                                    className="w-full px-3 py-2 rounded-xl border border-blue-200 focus:ring-2 focus:ring-blue-500 outline-none text-sm"
                                    placeholder="e.g. 4"
                                    value={data.installments?.installmentsCount || ''}
                                    onChange={(e) => handleInstallmentChange('count', e.target.value)}
                                />
                            </div>
                        </div>

                        {/* Dynamic Installment Dates */}
                        {(parseInt(data.installments?.installmentsCount) > 0) && (
                            <div className="space-y-3 mt-4">
                                <h4 className="flex justify-between items-center text-xs font-bold text-gray-500 border-b border-gray-100 pb-2">
                                    <span>جدول الأقساط (Installment Schedule) - (Month Only)</span>
                                    {(() => {
                                        const count = parseInt(data.installments?.installmentsCount) || 0;
                                        const dp = parseFloat(data.installments?.downPayment) || 0;
                                        const total = dp +
                                            Array.from({ length: count }).reduce((acc, _, i) => acc + (parseFloat(data.installments?.dates?.[`rate_${i}`]) || 0), 0);
                                        const isValid = Math.abs(total - 100) < 0.1;
                                        return (
                                            <span className={`px-2 py-0.5 rounded text-[10px] ${isValid ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                                                Total: {total.toFixed(1)}% {isValid ? '✓' : '(Must be 100%)'}
                                            </span>
                                        );
                                    })()}
                                </h4>

                                {/* Down Payment Date */}
                                <div className="flex items-center gap-4 p-3 bg-white border border-gray-200 rounded-xl">
                                    <div className="w-8 h-8 rounded-full bg-blue-100 text-blue-600 flex items-center justify-center font-bold text-xs">DP</div>
                                    <div className="flex-1">
                                        <label className="text-xs font-bold text-gray-700 block">موعد الدفعة المقدمة</label>
                                        <p className="text-[10px] text-gray-400">Down Payment Month</p>
                                    </div>
                                    <div className="relative w-24 opacity-50">
                                        <input
                                            readOnly
                                            type="text"
                                            className="w-full pl-3 pr-6 py-2 rounded-lg border border-gray-200 text-sm text-center font-mono bg-gray-50"
                                            value={data.installments?.downPayment || ''}
                                        />
                                        <span className="absolute right-2 top-2 text-gray-400 text-xs font-bold">%</span>
                                    </div>
                                    <select
                                        className="w-32 px-3 py-2 rounded-lg border border-gray-200 text-sm font-medium focus:ring-2 focus:ring-blue-500 outline-none direction-rtl"
                                        value={data.installments?.dates?.downPayment || ''}
                                        onChange={(e) => updateData({
                                            installments: {
                                                ...data.installments,
                                                dates: { ...(data.installments?.dates || {}), downPayment: e.target.value }
                                            }
                                        })}
                                    >
                                        <option value="">Month</option>
                                        {['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'].map((m, i) => (
                                            <option key={i} value={i + 1}>{m}</option>
                                        ))}
                                    </select>
                                </div>

                                {/* Installments Loop */}
                                {Array.from({ length: Math.min(parseInt(data.installments?.installmentsCount) || 0, 12) }).map((_, idx) => (
                                    <div key={idx} className="flex items-center gap-4 p-3 bg-white border border-gray-200 rounded-xl">
                                        <div className="w-8 h-8 rounded-full bg-gray-100 text-gray-600 flex items-center justify-center font-bold text-xs">{idx + 1}</div>
                                        <div className="flex-1">
                                            <label className="text-xs font-bold text-gray-700 block">القسط {idx + 1}</label>
                                            <p className="text-[10px] text-gray-400">Installment {idx + 1}</p>
                                        </div>

                                        {/* Rate Input */}
                                        <div className="relative w-24">
                                            <input
                                                type="number"
                                                placeholder="Rate"
                                                className="w-full pl-3 pr-6 py-2 rounded-lg border border-gray-200 text-sm text-center font-mono focus:ring-2 focus:ring-blue-500 outline-none"
                                                value={data.installments?.dates?.[`rate_${idx}`] !== undefined ? data.installments?.dates?.[`rate_${idx}`] : ''}
                                                onChange={(e) => handleInstallmentChange('rate', e.target.value, idx)}
                                            />
                                            <span className="absolute right-2 top-2 text-gray-400 text-xs font-bold">%</span>
                                        </div>

                                        {/* Date Input */}
                                        <select
                                            className="w-32 px-3 py-2 rounded-lg border border-gray-200 text-sm font-medium focus:ring-2 focus:ring-blue-500 outline-none direction-rtl"
                                            value={data.installments?.dates?.[`inst_${idx}`] || ''}
                                            onChange={(e) => updateData({
                                                installments: {
                                                    ...data.installments,
                                                    dates: { ...(data.installments?.dates || {}), [`inst_${idx}`]: e.target.value }
                                                }
                                            })}
                                        >
                                            <option value="">Month</option>
                                            {['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'].map((m, i) => (
                                                <option key={i} value={i + 1}>{m}</option>
                                            ))}
                                        </select>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                )}
            </div>

            <div className="grid grid-cols-1 gap-8">

                {/* Fees Configuration per Active Class */}
                {loading ? (
                    <div className="p-8 text-center text-gray-400">جاري تحميل بيانات الصفوف...</div>
                ) : (
                    <div className="space-y-6">
                        {structure?.stages?.map(stage => {
                            const stageConfig = s.stages[stage.id];
                            if (!stageConfig?.active) return null;

                            const activeGrades = [];

                            // Helper to collect active grades
                            const processGrades = (grades) => {
                                grades?.forEach(g => {
                                    // Check if any class in this grade is active
                                    const activeClasses = g.classes?.filter(c => s.classes[c.id]?.active) || [];
                                    if (activeClasses.length > 0) {
                                        activeGrades.push({ ...g, activeClasses });
                                    }
                                });
                            };

                            processGrades(stage.grades);
                            stage.branches?.forEach(b => processGrades(b.grades));

                            if (activeGrades.length === 0) return null;

                            return (
                                <div key={stage.id} className="bg-white border border-gray-100 rounded-2xl overflow-hidden shadow-sm">
                                    <div className="bg-gray-50/50 p-4 border-b border-gray-100 flex justify-between items-center">
                                        <h3 className="font-bold text-gray-800">{stage.name}</h3>
                                        {stageConfig.customName && <span className="text-xs bg-amber-100 text-amber-700 px-2 py-1 rounded-full">{stageConfig.customName}</span>}
                                    </div>
                                    <div className="p-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                                        {activeGrades.map(grade => (
                                            grade.activeClasses.map(cls => (
                                                <div key={cls.id} className="p-3 border border-gray-200 rounded-xl hover:border-blue-300 transition-colors">
                                                    <div className="mb-2">
                                                        <div className="flex justify-between items-start">
                                                            <span className="text-sm font-bold text-gray-700 block">{grade.name}</span>
                                                            {s.classes[cls.id]?.customName && <span className="text-[10px] text-blue-600 bg-blue-50 px-1.5 py-0.5 rounded ml-2">{s.classes[cls.id].customName}</span>}
                                                        </div>
                                                        {grade.activeClasses.length > 1 && <span className="text-xs text-gray-400">فصل: {cls.name}</span>}
                                                    </div>
                                                    <div className="grid grid-cols-[1.5fr_1fr_auto] gap-2 mt-2 items-center">
                                                        <div className="relative">
                                                            <FiDollarSign className="absolute right-3 top-2.5 text-gray-400" size={14} />
                                                            <input
                                                                type="number"
                                                                placeholder="مصاريف"
                                                                className="w-full pr-8 pl-3 py-2 text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                                                                value={s.classes[cls.id]?.fees || ''}
                                                                onChange={(e) => updateClassFees(cls.id, e.target.value)}
                                                            />
                                                        </div>
                                                        <div className="relative">
                                                            <input
                                                                type="number"
                                                                placeholder="خصم %"
                                                                className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:ring-2 focus:ring-red-500 outline-none text-center"
                                                                value={s.classes[cls.id]?.discount || ''}
                                                                onChange={(e) => updateClassDiscount(cls.id, e.target.value)}
                                                            />
                                                        </div>
                                                        {s.classes[cls.id]?.fees > 0 && (
                                                            <button
                                                                type="button"
                                                                onClick={() => setPreviewClass({
                                                                    ...cls,
                                                                    fees: s.classes[cls.id]?.fees,
                                                                    discount: s.classes[cls.id]?.discount
                                                                })}
                                                                className="p-2 bg-blue-50 text-blue-600 rounded-lg hover:bg-blue-100 transition shadow-sm"
                                                                title="جدول الأقساط (Installment Schedule)"
                                                            >
                                                                <FiEye size={16} />
                                                            </button>
                                                        )}
                                                    </div>
                                                </div>
                                            ))
                                        ))}
                                    </div>
                                </div>
                            );
                        })}

                        {(!structure || !Object.values(s.stages).some(st => st.active)) && (
                            <div className="text-center p-6 bg-yellow-50 rounded-xl border border-yellow-100 text-yellow-700">
                                يرجى تحديد المراحل والصفوف الدراسية أولاً في الخطوة السابقة.
                            </div>
                        )}
                    </div>
                )}

                {/* Application Period Section */}
                <div>
                    <div className="flex items-center gap-4 mb-4 mt-8">
                        <div className="p-3 bg-amber-100 text-amber-600 rounded-xl">
                            <FiCalendar size={24} />
                        </div>
                        <div>
                            <h2 className="text-xl font-bold text-gray-800">فترة التقديم السنوية (Recurring Admission Period)</h2>
                            <p className="text-gray-500 text-sm">حدد موعد بدء ونهاية استقبال الطلبات (يتكرر كل عام)</p>
                        </div>
                    </div>

                    <div className="bg-white border border-gray-100 rounded-2xl p-6 shadow-sm">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                            {/* Start Period */}
                            <div className="space-y-3">
                                <label className="block text-sm font-bold text-gray-700 border-r-4 border-amber-400 pr-3">موعد بدء التقديم</label>
                                <div className="grid grid-cols-2 gap-3">
                                    <div className="space-y-1">
                                        <span className="text-[10px] font-bold text-gray-400 block pr-1">الشهر</span>
                                        <select
                                            className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-amber-500 outline-none bg-gray-50/50 text-sm font-medium"
                                            value={data.admissionDetails?.applicationStartMonth || ''}
                                            onChange={(e) => updateData({ admissionDetails: { ...(data.admissionDetails || {}), applicationStartMonth: parseInt(e.target.value) } })}
                                        >
                                            <option value="">اختر الشهر</option>
                                            {['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'].map((m, i) => (
                                                <option key={i} value={i + 1}>{m} ({i + 1})</option>
                                            ))}
                                        </select>
                                    </div>
                                    <div className="space-y-1">
                                        <span className="text-[10px] font-bold text-gray-400 block pr-1">اليوم</span>
                                        <select
                                            className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-amber-500 outline-none bg-gray-50/50 text-sm font-medium"
                                            value={data.admissionDetails?.applicationStartDay || ''}
                                            onChange={(e) => updateData({ admissionDetails: { ...(data.admissionDetails || {}), applicationStartDay: parseInt(e.target.value) } })}
                                        >
                                            <option value="">اليوم</option>
                                            {Array.from({ length: 31 }).map((_, i) => (
                                                <option key={i} value={i + 1}>{i + 1}</option>
                                            ))}
                                        </select>
                                    </div>
                                </div>
                            </div>

                            {/* End Period */}
                            <div className="space-y-3">
                                <label className="block text-sm font-bold text-gray-700 border-r-4 border-red-400 pr-3">موعد نهاية التقديم</label>
                                <div className="grid grid-cols-2 gap-3">
                                    <div className="space-y-1">
                                        <span className="text-[10px] font-bold text-gray-400 block pr-1">الشهر</span>
                                        <select
                                            className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-amber-500 outline-none bg-gray-50/50 text-sm font-medium"
                                            value={data.admissionDetails?.applicationEndMonth || ''}
                                            onChange={(e) => updateData({ admissionDetails: { ...(data.admissionDetails || {}), applicationEndMonth: parseInt(e.target.value) } })}
                                        >
                                            <option value="">اختر الشهر</option>
                                            {['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'].map((m, i) => (
                                                <option key={i} value={i + 1}>{m} ({i + 1})</option>
                                            ))}
                                        </select>
                                    </div>
                                    <div className="space-y-1">
                                        <span className="text-[10px] font-bold text-gray-400 block pr-1">اليوم</span>
                                        <select
                                            className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-amber-500 outline-none bg-gray-50/50 text-sm font-medium"
                                            value={data.admissionDetails?.applicationEndDay || ''}
                                            onChange={(e) => updateData({ admissionDetails: { ...(data.admissionDetails || {}), applicationEndDay: parseInt(e.target.value) } })}
                                        >
                                            <option value="">اليوم</option>
                                            {Array.from({ length: 31 }).map((_, i) => (
                                                <option key={i} value={i + 1}>{i + 1}</option>
                                            ))}
                                        </select>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                {/* General Financials Section */}
                <div>
                    <div className="flex items-center gap-4 mb-4 mt-8">
                        <div className="p-3 bg-emerald-100 text-emerald-600 rounded-xl">
                            <FiDollarSign size={24} />
                        </div>
                        <div>
                            <h2 className="text-xl font-bold text-gray-800">بيانات مالية عامة</h2>
                            <p className="text-gray-500 text-sm">مصروفات التسجيل، الباص، والزي المدرسي</p>
                        </div>
                    </div>

                    <div className="bg-white border border-gray-100 rounded-2xl p-6 shadow-sm space-y-6">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            {/* Registration Fees */}
                            {/* Registration Fees with Discount Toggle */}
                            <div className="space-y-2">
                                <div className="flex justify-between items-center">
                                    <label className="block text-sm font-bold text-gray-700">مصروفات التسجيل (Registration)</label>
                                    <div className="flex items-center gap-2 cursor-pointer" onClick={() => updateData({
                                        financials: {
                                            ...(data.financials || {}),
                                            registrationDiscountEnabled: !data.financials?.registrationDiscountEnabled
                                        }
                                    })}>
                                        <span className="text-xs text-gray-500 font-medium">خصم (Discount)?</span>
                                        <div className={`w-9 h-5 rounded-full transition-colors relative ${data.financials?.registrationDiscountEnabled ? 'bg-emerald-500' : 'bg-gray-200'}`}>
                                            <div className={`absolute top-0.5 w-4 h-4 bg-white rounded-full transition-all shadow-sm ${data.financials?.registrationDiscountEnabled ? 'left-[18px]' : 'left-0.5'}`} />
                                        </div>
                                    </div>
                                </div>
                                <div className="flex gap-3">
                                    <div className="relative w-full">
                                        <input
                                            type="number"
                                            className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-emerald-500 outline-none"
                                            placeholder="0"
                                            value={data.financials?.registrationFees || ''}
                                            onChange={(e) => updateData({ financials: { ...(data.financials || {}), registrationFees: e.target.value } })}
                                        />
                                        <span className="absolute right-4 top-3.5 text-gray-400 text-xs">EGP</span>
                                    </div>

                                    {data.financials?.registrationDiscountEnabled && (
                                        <div className="relative w-1/2 animate-in fade-in slide-in-from-right-4 duration-300">
                                            <input
                                                type="number"
                                                className="w-full pl-3 pr-8 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-red-500 outline-none text-center font-bold text-red-600 bg-red-50/50"
                                                placeholder="0"
                                                value={data.financials?.registrationDiscount || ''}
                                                onChange={(e) => updateData({ financials: { ...(data.financials || {}), registrationDiscount: e.target.value } })}
                                            />
                                            <span className="absolute right-3 top-3.5 text-red-400 text-xs font-bold">%</span>
                                        </div>
                                    )}
                                </div>
                            </div>

                            {/* Uniform Fees with Discount Toggle */}
                            <div className="space-y-2">
                                <div className="flex justify-between items-center">
                                    <label className="block text-sm font-bold text-gray-700">مصاريف الزي المدرسي (Uniform)</label>
                                    <div className="flex items-center gap-2 cursor-pointer" onClick={() => updateData({
                                        financials: {
                                            ...(data.financials || {}),
                                            uniformDiscountEnabled: !data.financials?.uniformDiscountEnabled
                                        }
                                    })}>
                                        <span className="text-xs text-gray-500 font-medium">خصم (Discount)?</span>
                                        <div className={`w-9 h-5 rounded-full transition-colors relative ${data.financials?.uniformDiscountEnabled ? 'bg-emerald-500' : 'bg-gray-200'}`}>
                                            <div className={`absolute top-0.5 w-4 h-4 bg-white rounded-full transition-all shadow-sm ${data.financials?.uniformDiscountEnabled ? 'left-[18px]' : 'left-0.5'}`} />
                                        </div>
                                    </div>
                                </div>
                                <div className="flex gap-3">
                                    <div className="relative w-full">
                                        <input
                                            type="number"
                                            className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-emerald-500 outline-none"
                                            placeholder="0"
                                            value={data.financials?.uniformFees || ''}
                                            onChange={(e) => updateData({ financials: { ...(data.financials || {}), uniformFees: e.target.value } })}
                                        />
                                        <span className="absolute right-4 top-3.5 text-gray-400 text-xs">EGP</span>
                                    </div>

                                    {data.financials?.uniformDiscountEnabled && (
                                        <div className="relative w-1/2 animate-in fade-in slide-in-from-right-4 duration-300">
                                            <input
                                                type="number"
                                                className="w-full pl-3 pr-8 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-red-500 outline-none text-center font-bold text-red-600 bg-red-50/50"
                                                placeholder="0"
                                                value={data.financials?.uniformDiscount || ''}
                                                onChange={(e) => updateData({ financials: { ...(data.financials || {}), uniformDiscount: e.target.value } })}
                                            />
                                            <span className="absolute right-3 top-3.5 text-red-400 text-xs font-bold">%</span>
                                        </div>
                                    )}
                                </div>
                            </div>
                        </div>

                        {/* Bus Subscription */}
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-2">اشتراك الباص (Bus Subscription)</label>
                            <div className="grid grid-cols-2 gap-4">
                                <input
                                    type="number"
                                    className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-emerald-500 outline-none"
                                    placeholder="الحد الأدنى (Min)"
                                    value={data.financials?.busFeesMin || ''}
                                    onChange={(e) => updateData({ financials: { ...(data.financials || {}), busFeesMin: e.target.value } })}
                                />
                                <input
                                    type="number"
                                    className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:ring-2 focus:ring-emerald-500 outline-none"
                                    placeholder="الحد الأقصى (Max)"
                                    value={data.financials?.busFeesMax || ''}
                                    onChange={(e) => updateData({ financials: { ...(data.financials || {}), busFeesMax: e.target.value } })}
                                />
                            </div>
                        </div>
                    </div>
                </div>






            </div>

            {/* Installment Preview Modal */}
            {previewClass && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 animate-in fade-in duration-200" style={{ margin: 0 }}>
                    <div className="bg-white w-full max-w-md rounded-2xl shadow-2xl overflow-hidden max-h-[90vh] flex flex-col">
                        <div className="bg-blue-600 p-4 text-white flex justify-between items-center shrink-0">
                            <div>
                                <h3 className="font-bold text-lg">{previewClass.name}</h3>
                                <p className="text-blue-100 text-xs">جدول الأقساط المتوقع (Installment Schedule)</p>
                            </div>
                            <button onClick={() => setPreviewClass(null)} className="p-1 hover:bg-white/20 rounded-full transition"><FiX size={20} /></button>
                        </div>

                        <div className="p-6 space-y-4 overflow-y-auto custom-scrollbar">
                            {/* Summary */}
                            <div className="flex justify-between items-center bg-gray-50 p-3 rounded-xl border border-gray-100 shrink-0">
                                <div className="text-center">
                                    <span className="block text-xs text-gray-500">المصاريف</span>
                                    <span className="font-bold text-gray-800">{previewClass.fees}</span>
                                </div>
                                {(parseFloat(previewClass.discount) > 0) && (
                                    <>
                                        <div className="h-8 w-px bg-gray-200"></div>
                                        <div className="text-center">
                                            <span className="block text-xs text-red-500">خصم ({previewClass.discount}%)</span>
                                            <span className="font-bold text-red-600">-{((previewClass.fees * previewClass.discount) / 100).toFixed(0)}</span>
                                        </div>
                                    </>
                                )}
                                <div className="h-8 w-px bg-gray-200"></div>
                                <div className="text-center">
                                    <span className="block text-xs text-blue-500">الصافي (Net)</span>
                                    <span className="font-bold text-blue-600 text-lg">{(previewClass.fees * (1 - (previewClass.discount || 0) / 100)).toFixed(0)}</span>
                                </div>
                            </div>

                            {/* Timeline */}
                            <div className="relative border-r border-gray-200 mr-3 space-y-6 pr-6">
                                {(() => {
                                    const net = previewClass.fees * (1 - (previewClass.discount || 0) / 100);
                                    const dpVal = parseFloat(data.installments?.downPayment) || 0;
                                    const dpAmount = net * (dpVal / 100);

                                    const monthNames = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

                                    const count = parseInt(data.installments?.installmentsCount) || 0;

                                    return (
                                        <>
                                            {/* Down Payment */}
                                            <div className="relative">
                                                <div className="absolute -right-[29px] top-1 w-3 h-3 bg-blue-600 rounded-full border-2 border-white shadow-sm ring-1 ring-blue-100"></div>
                                                <div className="flex justify-between items-start">
                                                    <div>
                                                        <span className="block text-xs font-bold text-gray-800">الدفعة المقدمة ({dpVal}%)</span>
                                                        <span className="text-[10px] text-gray-500">{monthNames[data.installments?.dates?.downPayment] || '-'}</span>
                                                    </div>
                                                    <span className="font-bold text-blue-600">{dpAmount.toFixed(0)} ج.م</span>
                                                </div>
                                            </div>

                                            {/* Installments */}
                                            {Array.from({ length: count }).map((_, i) => {
                                                const rate = parseFloat(data.installments?.dates?.[`rate_${i}`]) || 0;
                                                const amount = net * (rate / 100);
                                                const month = data.installments?.dates?.[`inst_${i}`];

                                                return (
                                                    <div key={i} className="relative">
                                                        <div className="absolute -right-[29px] top-1 w-3 h-3 bg-white border-2 border-gray-300 rounded-full"></div>
                                                        <div className="flex justify-between items-start">
                                                            <div>
                                                                <span className="block text-xs font-bold text-gray-700">القسط {i + 1} ({rate}%)</span>
                                                                <span className="text-[10px] text-gray-500">{monthNames[month] || '-'}</span>
                                                            </div>
                                                            <span className="font-mono text-gray-600 font-medium">{amount.toFixed(0)} ج.م</span>
                                                        </div>
                                                    </div>
                                                );
                                            })}
                                        </>
                                    );
                                })()}
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}


