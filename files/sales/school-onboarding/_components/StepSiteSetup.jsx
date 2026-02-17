import { FiLayout, FiEye, FiCheckCircle, FiUpload, FiImage, FiX, FiTrash2 } from 'react-icons/fi';

export default function StepSiteSetup({ data, updateData }) {
    return (
        <div className="space-y-6 animate-in fade-in slide-in-from-right-8 duration-500">
            <div className="flex items-center gap-4 mb-6">
                <div className="p-3 bg-pink-100 text-pink-600 rounded-xl">
                    <FiLayout size={24} />
                </div>
                <div>
                    <h2 className="text-xl font-bold text-gray-800">إعدادات الظهور والموقع</h2>
                    <p className="text-gray-500 text-sm">تخصيص هوية المدرسة وظهورها على المنصة</p>
                </div>
            </div>

            {/* Images & Identity Section */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                {/* Logo Upload */}
                <div className="space-y-4">
                    <h3 className="font-bold text-gray-700 flex items-center gap-2">
                        <FiImage className="text-blue-500" /> شعار المدرسة
                    </h3>
                    <div className="bg-white border-2 border-dashed border-gray-200 rounded-2xl p-6 flex flex-col items-center justify-center text-center hover:border-blue-400 transition-colors relative group">
                        {data.logo ? (
                            <div className="relative w-32 h-32">
                                <img src={data.logo} alt="Logo" className="w-full h-full object-contain rounded-xl" />
                                <button
                                    onClick={() => updateData({ logo: null })}
                                    className="absolute -top-2 -right-2 bg-red-500 text-white p-1 rounded-full opacity-0 group-hover:opacity-100 transition-opacity shadow-md"
                                >
                                    <FiTrash2 size={14} />
                                </button>
                            </div>
                        ) : (
                            <div className="text-gray-400">
                                <FiUpload size={32} className="mx-auto mb-2" />
                                <span className="text-sm font-medium">اضغط لرفع الشعار</span>
                            </div>
                        )}
                        <input
                            type="file"
                            accept="image/*"
                            className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                            onChange={(e) => {
                                const file = e.target.files[0];
                                if (!file) return;
                                const reader = new FileReader();
                                reader.onload = (ev) => updateData({ logo: ev.target.result });
                                reader.readAsDataURL(file);
                            }}
                        />
                    </div>
                </div>

                {/* Buildings Upload */}
                <div className="space-y-4">
                    <h3 className="font-bold text-gray-700 flex items-center gap-2">
                        <FiLayout className="text-blue-500" /> صور المبنى المدرسي
                    </h3>
                    <div className="bg-white border-2 border-dashed border-gray-200 rounded-2xl p-4 min-h-[180px] hover:border-blue-400 transition-colors relative">
                        {(!data.buildings || data.buildings.length === 0) && (
                            <div className="absolute inset-0 flex flex-col items-center justify-center text-gray-400 pointer-events-none">
                                <FiImage size={32} className="mb-2" />
                                <span className="text-sm font-medium">رفع صور المباني</span>
                            </div>
                        )}

                        <div className="grid grid-cols-3 gap-2 relative z-10">
                            {(data.buildings || []).map((img, idx) => (
                                <div key={idx} className="relative aspect-square rounded-lg overflow-hidden group border border-gray-100">
                                    <img src={img} alt={`Building ${idx}`} className="w-full h-full object-cover" />
                                    <button
                                        onClick={() => {
                                            const newBuildings = [...data.buildings];
                                            newBuildings.splice(idx, 1);
                                            updateData({ buildings: newBuildings });
                                        }}
                                        className="absolute top-1 right-1 bg-black/50 text-white p-1 rounded-full opacity-0 group-hover:opacity-100 transition-opacity hover:bg-red-500"
                                    >
                                        <FiX size={12} />
                                    </button>
                                </div>
                            ))}
                            <label className="aspect-square flex items-center justify-center bg-gray-50 rounded-lg cursor-pointer hover:bg-gray-100 border border-gray-200 text-gray-400 hover:text-blue-500 transition-colors">
                                <FiUpload size={20} />
                                <input
                                    type="file"
                                    multiple
                                    accept="image/*"
                                    className="hidden"
                                    onChange={(e) => {
                                        const files = Array.from(e.target.files);
                                        if (files.length === 0) return;

                                        Promise.all(files.map(file => new Promise((resolve) => {
                                            const reader = new FileReader();
                                            reader.onload = (ev) => resolve(ev.target.result);
                                            reader.readAsDataURL(file);
                                        }))).then(newImages => {
                                            updateData({ buildings: [...(data.buildings || []), ...newImages] });
                                        });
                                    }}
                                />
                            </label>
                        </div>
                    </div>
                </div>
            </div>

            <div className="border-t border-gray-200 my-6"></div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">

                {/* Visibility Toggles */}
                <div className="space-y-4">
                    <h3 className="font-bold text-gray-700">حالة الظهور</h3>

                    <label className="flex items-center gap-4 p-4 border border-gray-200 rounded-xl cursor-pointer hover:bg-gray-50 transition-colors bg-white">
                        <input
                            type="checkbox"
                            className="w-5 h-5 accent-blue-600"
                            checked={data.approved}
                            onChange={(e) => updateData({ approved: e.target.checked })}
                        />
                        <div>
                            <span className="block font-bold text-gray-800">تفعيل المدرسة (Approved)</span>
                            <span className="text-xs text-gray-500">تسمح للمستخدمين بالوصول للمدرسة</span>
                        </div>
                    </label>

                    <label className="flex items-center gap-4 p-4 border border-gray-200 rounded-xl cursor-pointer hover:bg-gray-50 transition-colors bg-white">
                        <input
                            type="checkbox"
                            className="w-5 h-5 accent-pink-600"
                            checked={data.showInSearch}
                            onChange={(e) => updateData({ showInSearch: e.target.checked })}
                        />
                        <div>
                            <span className="block font-bold text-gray-800">إظهار في البحث</span>
                            <span className="text-xs text-gray-500">تظهر المدرسة في نتائج البحث العامة</span>
                        </div>
                    </label>
                </div>

                {/* Theme Colors */}
                <div className="space-y-4">
                    <h3 className="font-bold text-gray-700">ألوان الهوية (Theme)</h3>

                    <div className="flex items-center gap-4 bg-white p-3 rounded-xl border border-gray-100">
                        <input
                            type="color"
                            className="w-12 h-12 rounded-xl cursor-pointer border-none p-0 overflow-hidden"
                            value={data.theme?.primaryColor || '#3b82f6'}
                            onChange={(e) => updateData({ theme: { ...data.theme, primaryColor: e.target.value } })}
                        />
                        <div>
                            <span className="block text-sm font-bold">اللون الأساسي</span>
                            <span className="text-xs text-gray-500 dir-ltr block text-left">{data.theme?.primaryColor}</span>
                        </div>
                    </div>

                    <div className="flex items-center gap-4 bg-white p-3 rounded-xl border border-gray-100">
                        <input
                            type="color"
                            className="w-12 h-12 rounded-xl cursor-pointer border-none p-0 overflow-hidden"
                            value={data.theme?.secondaryColor || '#1d4ed8'}
                            onChange={(e) => updateData({ theme: { ...data.theme, secondaryColor: e.target.value } })}
                        />
                        <div>
                            <span className="block text-sm font-bold">اللون الفرعي</span>
                            <span className="text-xs text-gray-500 dir-ltr block text-left">{data.theme?.secondaryColor}</span>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    );
}
