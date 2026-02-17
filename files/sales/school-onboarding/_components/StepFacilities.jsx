import { useState, useEffect } from 'react';
import { FiActivity, FiCheck, FiUpload, FiX, FiImage, FiTrash2, FiPlus } from 'react-icons/fi';
import { toast } from 'react-hot-toast';

export default function StepFacilities({ data, updateData }) {
    const [facilities, setFacilities] = useState([]);
    const [loadingFacilities, setLoadingFacilities] = useState(true);
    const [isAddingNew, setIsAddingNew] = useState(false);
    const [isSubmittingNew, setIsSubmittingNew] = useState(false);
    const [newFacility, setNewFacility] = useState({
        name: '',
        description: '',
        icon: 'fi fi-rr-star', // default
        color: '#6366f1', // default indigo
        category: 'Services'
    });

    useEffect(() => {
        const fetchFacilities = async () => {
            try {
                const res = await fetch('/api/admin/facilities');
                const result = await res.json();
                if (result.success) {
                    setFacilities(result.facilities);
                }
            } catch (error) {
                console.error("Failed to load facilities", error);
            } finally {
                setLoadingFacilities(false);
            }
        };
        fetchFacilities();
    }, []);

    const toggleFacility = (facilityId) => {
        const currentFacilities = data.facilities || [];
        const exists = currentFacilities.some(f => f.facilityId === facilityId);

        let newFacilities;
        if (exists) {
            newFacilities = currentFacilities.filter(f => f.facilityId !== facilityId);
        } else {
            // Find the facility details to include name/icon
            const facilityDetails = facilities.find(f => f.id === facilityId);
            newFacilities = [...currentFacilities, {
                facilityId,
                value: 'Yes',
                images: [],
                name: facilityDetails?.name,
                icon: facilityDetails?.icon
            }];
        }
        updateData({ facilities: newFacilities });
    };

    const handleImageUpload = (facilityId, e) => {
        e.stopPropagation();
        const files = Array.from(e.target.files);
        if (files.length === 0) return;

        const filePromises = files.map(file => {
            return new Promise((resolve) => {
                const reader = new FileReader();
                reader.onload = (e) => resolve({
                    name: file.name,
                    data: e.target.result, // Base64
                    type: file.type
                });
                reader.readAsDataURL(file);
            });
        });

        Promise.all(filePromises).then(newImages => {
            const currentFacilities = data.facilities || [];
            const newFacilities = currentFacilities.map(f => {
                if (f.facilityId === facilityId) {
                    return { ...f, images: [...(f.images || []), ...newImages] };
                }
                return f;
            });
            updateData({ facilities: newFacilities });
        });
    };

    const removeImage = (facilityId, imgIndex, e) => {
        e.stopPropagation();
        const currentFacilities = data.facilities || [];
        const newFacilities = currentFacilities.map(f => {
            if (f.facilityId === facilityId) {
                const newImages = [...(f.images || [])];
                newImages.splice(imgIndex, 1);
                return { ...f, images: newImages };
            }
            return f;
        });
        updateData({ facilities: newFacilities });
    };

    const handleAddGlobalFacility = async () => {
        if (!newFacility.name) {
            toast.error('اسم المرفق مطلوب');
            return;
        }
        setIsSubmittingNew(true);
        try {
            const res = await fetch('/api/admin/facilities', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(newFacility)
            });
            const result = await res.json();
            if (result.success) {
                const created = result.facility;
                // Add to local list
                setFacilities(prev => [...prev, created]);
                // Select it for the school immediately
                toggleFacility(created.id);
                // Reset and close
                setNewFacility({ name: '', description: '', icon: 'fi fi-rr-star', color: '#6366f1', category: 'Services' });
                setIsAddingNew(false);
                toast.success('تمت إضافة المرفق وتحديده بنجاح');
            } else {
                toast.error(result.message || 'فشل في إضافة المرفق');
            }
        } catch (error) {
            console.error(error);
            toast.error('حدث خطأ أثناء إضافة المرفق');
        } finally {
            setIsSubmittingNew(false);
        }
    };

    return (
        <div className="space-y-6 animate-in fade-in slide-in-from-right-8 duration-500">
            <div>
                <div className="flex items-center justify-between mb-4 mt-8">
                    <div className="flex items-center gap-4">
                        <div className="p-3 bg-purple-100 text-purple-600 rounded-xl">
                            <FiActivity size={24} />
                        </div>
                        <div>
                            <h2 className="text-xl font-bold text-gray-800">المرافق والخدمات</h2>
                            <p className="text-gray-500 text-sm">حدد الخدمات والمرافق المتاحة في المدرسة وقم برفع صور لها</p>
                        </div>
                    </div>
                    <button
                        onClick={() => setIsAddingNew(true)}
                        className="flex items-center gap-2 px-4 py-2 bg-purple-50 text-purple-600 rounded-xl hover:bg-purple-100 transition-colors text-sm font-bold shadow-sm"
                    >
                        <FiPlus /> إضافة خدمة جديدة
                    </button>
                </div>

                {loadingFacilities ? (
                    <div className="text-center py-6 text-gray-400">جاري تحميل المرافق...</div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                        {facilities.map(facility => {
                            const selectedFacility = (data.facilities || []).find(f => f.facilityId === facility.id);
                            const isSelected = !!selectedFacility;

                            return (
                                <div
                                    key={facility.id}
                                    onClick={() => toggleFacility(facility.id)}
                                    className={`cursor-pointer border rounded-2xl p-4 transition-all duration-200 relative overflow-hidden group ${isSelected ? 'shadow-md ring-1 ring-purple-100' : 'bg-white border-gray-100 hover:border-gray-200'
                                        }`}
                                    style={isSelected ? {
                                        borderColor: facility.color,
                                        backgroundColor: '#fff',
                                    } : {}}
                                >
                                    {/* Selection Indicator */}
                                    {isSelected && (
                                        <div className="absolute top-0 right-0 p-1.5 rounded-bl-xl shadow-sm z-10" style={{ backgroundColor: facility.color }}>
                                            <FiCheck size={14} className="text-white" />
                                        </div>
                                    )}

                                    {/* Header Section */}
                                    <div className="flex items-start gap-4 mb-3">
                                        <div
                                            className={`w-12 h-12 rounded-xl flex items-center justify-center text-xl shrink-0 transition-colors`}
                                            style={{
                                                backgroundColor: isSelected ? `${facility.color}15` : '#f9fafb',
                                                color: isSelected ? facility.color : '#9ca3af'
                                            }}
                                        >
                                            <i className={facility.icon}></i>
                                        </div>
                                        <div className="flex-1">
                                            <h4 className="font-bold text-gray-800 text-sm mb-1">{facility.name}</h4>
                                            {facility.description && (
                                                <p className="text-[11px] leading-relaxed text-gray-400 line-clamp-2">{facility.description}</p>
                                            )}
                                        </div>
                                    </div>

                                    {/* Images Section (Only if selected) */}
                                    {isSelected && (
                                        <div className="mt-4 pt-3 border-t border-gray-100 animate-in fade-in slide-in-from-top-2">
                                            <div className="flex flex-wrap gap-2 mb-3">
                                                {selectedFacility.images?.map((img, idx) => (
                                                    <div key={idx} className="relative w-12 h-12 rounded-lg overflow-hidden border border-gray-200 group/img">
                                                        <img src={img.data} alt="preview" className="w-full h-full object-cover" />
                                                        <button
                                                            onClick={(e) => removeImage(facility.id, idx, e)}
                                                            className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover/img:opacity-100 transition-opacity text-white"
                                                        >
                                                            <FiX size={12} />
                                                        </button>
                                                    </div>
                                                ))}
                                            </div>

                                            <div className="flex items-center justify-between">
                                                <span className="text-[10px] text-gray-400 font-medium">
                                                    {selectedFacility.images?.length || 0} صور مرفقة
                                                </span>
                                                <label
                                                    onClick={(e) => e.stopPropagation()}
                                                    className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-50 hover:bg-gray-100 text-gray-600 rounded-lg text-xs font-bold cursor-pointer transition-colors border border-gray-200"
                                                >
                                                    <FiUpload size={12} />
                                                    <span>رفع صور</span>
                                                    <input
                                                        type="file"
                                                        multiple
                                                        accept="image/*"
                                                        className="hidden"
                                                        onChange={(e) => handleImageUpload(facility.id, e)}
                                                    />
                                                </label>
                                            </div>
                                        </div>
                                    )}
                                </div>
                            );
                        })}
                    </div>
                )}
            </div>

            {/* Modal for Adding New Global Facility */}
            {isAddingNew && (
                <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
                    <div className="bg-white rounded-2xl w-full max-w-md p-6 animate-in fade-in zoom-in-95 shadow-2xl relative">
                        <button
                            onClick={() => setIsAddingNew(false)}
                            className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 transition-colors bg-gray-100 rounded-full p-2"
                        >
                            <FiX size={20} />
                        </button>

                        <h3 className="text-lg font-bold text-gray-800 mb-6 flex items-center gap-2 border-b border-gray-100 pb-4">
                            <div className="p-2 bg-purple-100 text-purple-600 rounded-lg"><FiPlus /></div>
                            إضافة مرفق/خدمة جديدة للنظام
                        </h3>

                        <div className="space-y-4">
                            <div>
                                <label className="text-xs font-bold text-gray-500 mb-1 block">اسم المرفق (English/Arabic)</label>
                                <input
                                    type="text"
                                    className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-purple-500 outline-none bg-gray-50/50 focus:bg-white transition-all font-semibold text-sm"
                                    value={newFacility.name}
                                    onChange={e => setNewFacility({ ...newFacility, name: e.target.value })}
                                    placeholder="مثال: حمام سباحة / Swimming Pool"
                                />
                            </div>

                            <div>
                                <label className="text-xs font-bold text-gray-500 mb-1 block">الوصف</label>
                                <textarea
                                    className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-purple-500 outline-none h-24 bg-gray-50/50 focus:bg-white transition-all text-sm resize-none"
                                    value={newFacility.description}
                                    onChange={e => setNewFacility({ ...newFacility, description: e.target.value })}
                                    placeholder="وصف مختصر للمرفق..."
                                />
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="text-xs font-bold text-gray-500 mb-1 block">أيقونة (Class Name)</label>
                                    <input
                                        type="text"
                                        className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-purple-500 outline-none dir-ltr text-left text-sm font-mono bg-gray-50/50 focus:bg-white"
                                        value={newFacility.icon}
                                        onChange={e => setNewFacility({ ...newFacility, icon: e.target.value })}
                                        placeholder="fi fi-rr-star"
                                    />
                                    <p className="text-[10px] text-gray-400 mt-1">Flaticon Uicons classes</p>
                                </div>
                                <div>
                                    <label className="text-xs font-bold text-gray-500 mb-1 block">لون التمييز</label>
                                    <div className="flex items-center gap-2 p-1 border border-gray-200 rounded-xl bg-gray-50/50">
                                        <input
                                            type="color"
                                            className="w-10 h-10 rounded-lg cursor-pointer border-0 p-0 shadow-sm"
                                            value={newFacility.color}
                                            onChange={e => setNewFacility({ ...newFacility, color: e.target.value })}
                                        />
                                        <input
                                            type="text"
                                            className="w-full px-2 py-1 text-sm bg-transparent outline-none dir-ltr text-left font-mono text-gray-600"
                                            value={newFacility.color}
                                            onChange={e => setNewFacility({ ...newFacility, color: e.target.value })}
                                        />
                                    </div>
                                </div>
                            </div>

                            <div className="pt-6 flex gap-3">
                                <button
                                    onClick={handleAddGlobalFacility}
                                    disabled={isSubmittingNew}
                                    className="flex-1 py-3 bg-purple-600 text-white rounded-xl font-bold hover:bg-purple-700 transition-colors shadow-lg shadow-purple-200 disabled:opacity-70 disabled:cursor-not-allowed text-sm"
                                >
                                    {isSubmittingNew ? 'جاري الإضافة...' : 'حفظ وإضافة للنظام'}
                                </button>
                                <button
                                    onClick={() => setIsAddingNew(false)}
                                    disabled={isSubmittingNew}
                                    className="px-6 py-3 bg-gray-100 text-gray-600 rounded-xl font-bold hover:bg-gray-200 transition-colors text-sm"
                                >
                                    إلغاء
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
