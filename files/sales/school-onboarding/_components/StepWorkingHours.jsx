import { FiClock } from 'react-icons/fi';

export default function StepWorkingHours({ data, updateData }) {
    return (
        <div className="space-y-6 animate-in fade-in slide-in-from-right-8 duration-500">
            <div>
                <div className="flex items-center gap-4 mb-4 mt-8">
                    <div className="p-3 bg-blue-100 text-blue-600 rounded-xl">
                        <FiClock size={24} />
                    </div>
                    <div>
                        <h2 className="text-xl font-bold text-gray-800">مواعيد العمل الرسمية</h2>
                        <p className="text-gray-500 text-sm">حدد أيام وساعات الدوام المدرسي</p>
                    </div>
                </div>

                <div className="bg-white border border-gray-100 rounded-2xl p-6 shadow-sm space-y-6">
                    {/* Days Selection */}
                    <div>
                        <label className="block text-sm font-bold text-gray-700 mb-3">أيام العمل</label>
                        <div className="flex flex-wrap gap-2">
                            {['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'].map((day) => {
                                const isSelected = (data.workDays || []).includes(day);
                                return (
                                    <button
                                        type="button"
                                        key={day}
                                        onClick={() => {
                                            const currentDays = data.workDays || [];
                                            const newDays = isSelected
                                                ? currentDays.filter(d => d !== day)
                                                : [...currentDays, day];
                                            updateData({ workDays: newDays });
                                        }}
                                        className={`px-4 py-2 rounded-xl text-sm font-bold transition-all duration-200 ${isSelected
                                            ? 'bg-blue-600 text-white shadow-md shadow-blue-200'
                                            : 'bg-gray-50 text-gray-500 hover:bg-gray-100'
                                            }`}
                                    >
                                        {day}
                                    </button>
                                );
                            })}
                        </div>
                    </div>

                    {/* Time Selection */}
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-2">من الساعة</label>
                            <input
                                type="time"
                                className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50/50 focus:bg-white focus:ring-2 focus:ring-blue-500 transition-all outline-none"
                                value={data.workHours?.start || ''}
                                onChange={(e) => updateData({ workHours: { ...(data.workHours || {}), start: e.target.value } })}
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-gray-700 mb-2">إلى الساعة</label>
                            <input
                                type="time"
                                className="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50/50 focus:bg-white focus:ring-2 focus:ring-blue-500 transition-all outline-none"
                                value={data.workHours?.end || ''}
                                onChange={(e) => updateData({ workHours: { ...(data.workHours || {}), end: e.target.value } })}
                            />
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
