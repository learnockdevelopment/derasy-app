import { useState, useEffect } from 'react';
import { FiBook, FiCheck, FiInfo, FiLayers, FiCheckSquare, FiSquare, FiSettings, FiDollarSign, FiChevronDown, FiChevronLeft, FiEye, FiEyeOff, FiAlertCircle, FiPlus, FiTrash2 } from 'react-icons/fi';

export default function StepAcademicSettings({ data, updateData }) {
    const [structure, setStructure] = useState(null);
    const [loading, setLoading] = useState(false);
    const [expandedStages, setExpandedStages] = useState({});
    const [expandedGrades, setExpandedGrades] = useState({});
    const [expandedClasses, setExpandedClasses] = useState({});

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

    const getStructure = () => data.selectedStructure || { stages: {}, classes: {}, subjects: {} };

    // Helper to perform multiple updates at once to avoid stale state issues
    const bulkUpdate = (updates) => {
        let s = JSON.parse(JSON.stringify(getStructure())); // Deep copy to stay safe

        updates.forEach(({ type, id, changes }) => {
            const collection = type === 'stage' ? 'stages' : (type === 'class' ? 'classes' : 'subjects');
            if (!s[collection][id]) s[collection][id] = { active: type === 'stage' }; // Default init
            s[collection][id] = { ...s[collection][id], ...changes };
        });

        updateData({ selectedStructure: s });
    };

    const updateItem = (type, id, updates) => {
        bulkUpdate([{ type, id, changes: updates }]);
    };

    const addCustomSubject = (gradeId, name) => {
        if (!name.trim()) return;
        const s = JSON.parse(JSON.stringify(getStructure()));
        if (!s.customSubjects) s.customSubjects = {};
        if (!s.customSubjects[gradeId]) s.customSubjects[gradeId] = [];

        s.customSubjects[gradeId].push({
            id: `custom_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            name: name.trim(),
            custom: true
        });
        updateData({ selectedStructure: s });
    };

    const removeCustomSubject = (gradeId, subjectId) => {
        const s = JSON.parse(JSON.stringify(getStructure()));
        if (!s.customSubjects?.[gradeId]) return;

        s.customSubjects[gradeId] = s.customSubjects[gradeId].filter(sub => sub.id !== subjectId);
        updateData({ selectedStructure: s });
    };

    const handleSelectAll = (active = true) => {
        if (!structure) return;

        // Re-implementing simplified Select All logic
        const current = getStructure();
        const newStructure = { stages: {}, classes: {}, subjects: {} };

        // Helper to preserve existing data if present
        const merge = (collection, id, defaultVal) => {
            const existing = current[collection]?.[id] || {};
            return { ...defaultVal, ...existing, active };
        };

        structure.stages?.forEach(stage => {
            newStructure.stages[stage.id] = merge('stages', stage.id, { customName: '' });

            const processGrades = (grades) => {
                grades?.forEach(grade => {
                    grade.classes?.forEach(cls => {
                        newStructure.classes[cls.id] = merge('classes', cls.id, { customName: '', fees: 0 });
                        cls.subjects?.forEach(sub => {
                            newStructure.subjects[sub.id] = merge('subjects', sub.id, { customName: '' });
                        });
                    });
                });
            };
            processGrades(stage.grades);
            stage.branches?.forEach(b => processGrades(b.grades));
        });

        updateData({ selectedStructure: newStructure });
    };

    if (!data.educationSystemId) {
        return (
            <div className="flex flex-col items-center justify-center p-12 text-center bg-gray-50 rounded-2xl border-2 border-dashed border-gray-200">
                <FiInfo size={48} className="text-gray-300 mb-4" />
                <h3 className="text-lg font-bold text-gray-500">برجاء اختيار نظام التعليم في الخطوة السابقة أولاً</h3>
            </div>
        );
    }

    const s = getStructure();

    return (
        <div className="space-y-6 animate-in fade-in slide-in-from-right-8 duration-500 pb-10">
            <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-4">
                    <div className="p-3 bg-indigo-600 text-white shadow-lg rounded-2xl shadow-indigo-200">
                        <FiBook size={24} />
                    </div>
                    <div>
                        <h2 className="text-xl font-bold text-gray-800">الاعدادات الاكاديمية (المتقدمة)</h2>
                        <p className="text-gray-500 text-sm">حدد المراحل، الفصول، والمواد وقم بتخصيص مسمياتها</p>
                    </div>
                </div>
                <div className="flex gap-2">
                    <button
                        onClick={() => handleSelectAll(true)}
                        className="flex items-center gap-2 px-4 py-2 bg-white border border-indigo-100 text-indigo-600 shadow-sm rounded-xl text-sm font-bold hover:bg-indigo-50 transition-colors"
                    >
                        <FiCheckSquare /> اختيار الكل
                    </button>
                    <button
                        onClick={() => handleSelectAll(false)}
                        className="flex items-center gap-2 px-4 py-2 bg-white border border-slate-200 text-slate-500 shadow-sm rounded-xl text-sm font-bold hover:bg-slate-50 transition-colors"
                    >
                        <FiSquare /> إلغاء الكل
                    </button>
                </div>
            </div>

            {loading ? (
                <div className="space-y-4">
                    {[1, 2, 3].map(i => (
                        <div key={i} className="w-full h-24 bg-gray-100 rounded-xl animate-pulse"></div>
                    ))}
                </div>
            ) : structure ? (
                <div className="space-y-4">
                    {(() => {
                        const filteredStages = structure.stages?.filter(stage => {
                            const stageTrackId = stage.trackId?.id || stage.trackId?._id || stage.trackId;

                            // If user selected a specific track, show stages for that track OR global stages
                            if (data.educationTrackId) {
                                return stageTrackId === data.educationTrackId || !stageTrackId;
                            }

                            // If no track selected, show global stages
                            if (!stageTrackId) return true;

                            // fallback: if no track is selected but ALL stages have tracks,
                            // we show them all to avoid an empty screen, or show a message.
                            // Let's check if the system has tracks at all.
                            const hasSystemTracks = structure.tracks?.length > 0;
                            if (!hasSystemTracks) return true;

                            return false;
                        }) || [];

                        if (filteredStages.length === 0) {
                            return (
                                <div className="flex flex-col items-center justify-center p-12 text-center bg-slate-50 rounded-2xl border border-slate-200">
                                    <FiAlertCircle size={48} className="text-amber-400 mb-4" />
                                    <h3 className="text-lg font-bold text-slate-700">لا توجد مراحل دراسية متاحة</h3>
                                    <p className="text-slate-500 text-sm mt-2 max-w-md">
                                        {data.educationTrackId
                                            ? "هذا المسار التعليمي لا يحتوي على مراحل مسجلة حالياً."
                                            : "برجاء اختيار المسار التعليمي من الخطوة السابقة لتتمكن من رؤية المراحل المتاحة."}
                                    </p>
                                </div>
                            );
                        }

                        return filteredStages.map(stage => {
                            const isExpanded = expandedStages[stage.id];
                            const config = s.stages[stage.id] || { active: false };

                            return (
                                <div key={stage.id} className={`bg-white border rounded-2xl overflow-hidden transition-all duration-300 ${config.active ? 'border-indigo-200 shadow-md shadow-indigo-100' : 'border-slate-100 shadow-sm opacity-90'}`}>
                                    {/* Stage Header */}
                                    <div className={`p-4 flex items-center justify-between cursor-pointer transition-colors ${config.active ? 'bg-indigo-50/40' : 'hover:bg-slate-50'}`}>
                                        <div className="flex items-center gap-4 flex-1">
                                            <button
                                                onClick={() => {
                                                    const newState = !config.active;

                                                    const updates = [{ type: 'stage', id: stage.id, changes: { active: newState } }];

                                                    if (!newState) {
                                                        // Cascade Deactivate: Uncheck all children if stage is turned off
                                                        const deactivateGrades = (grades) => {
                                                            grades?.forEach(g => {
                                                                g.classes?.forEach(c => {
                                                                    updates.push({ type: 'class', id: c.id, changes: { active: false } });
                                                                    c.subjects?.forEach(s => {
                                                                        updates.push({ type: 'subject', id: s.id, changes: { active: false } });
                                                                    });
                                                                });
                                                            });
                                                        };
                                                        deactivateGrades(stage.grades);
                                                        stage.branches?.forEach(b => deactivateGrades(b.grades));
                                                    }

                                                    // Auto-expand if activating
                                                    if (newState) {
                                                        setExpandedStages(prev => ({ ...prev, [stage.id]: true }));
                                                    }
                                                    bulkUpdate(updates);
                                                }}
                                                className={`p-2.5 rounded-xl transition-all duration-200 border ${config.active ? 'bg-indigo-600 border-indigo-600 text-white shadow-lg shadow-indigo-200' : 'bg-white border-slate-200 text-slate-300 hover:border-indigo-300'}`}
                                            >
                                                {config.active ? <FiCheck size={18} /> : <div className="w-4.5 h-4.5" />}
                                            </button>

                                            <div className="flex-1" onClick={() => setExpandedStages({ ...expandedStages, [stage.id]: !isExpanded })}>
                                                <div className="flex items-center gap-3">
                                                    <span className={`text-lg transition-colors ${config.active ? 'font-bold text-indigo-900' : 'font-medium text-slate-600'}`}>{stage.name}</span>
                                                    {config.customName && <span className="text-[10px] bg-amber-100 text-amber-700 px-2 py-0.5 rounded-full font-bold">مسمى: {config.customName}</span>}
                                                </div>
                                                <div className="flex items-center gap-4 mt-1">
                                                    <span className="text-xs text-slate-400 flex items-center gap-1"><FiLayers size={12} /> {(stage.grades?.length || 0) + (stage.branches?.length || 0)} عناصر</span>
                                                </div>
                                            </div>
                                        </div>

                                        <div className="flex items-center gap-4">
                                            {config.active && (
                                                <div className="hidden md:block">
                                                    <input
                                                        type="text"
                                                        placeholder="تخصيص اسم المرحلة..."
                                                        value={config.customName || ''}
                                                        onChange={e => updateItem('stage', stage.id, { customName: e.target.value })}
                                                        className="px-4 py-2 border border-indigo-100 rounded-xl text-sm bg-white focus:ring-2 focus:ring-indigo-500 focus:border-transparent outline-none w-56 shadow-sm transition-all"
                                                        onClick={e => e.stopPropagation()}
                                                    />
                                                </div>
                                            )}
                                            <button
                                                onClick={() => setExpandedStages({ ...expandedStages, [stage.id]: !isExpanded })}
                                                className={`w-8 h-8 flex items-center justify-center rounded-full transition-all ${isExpanded ? 'bg-indigo-100 text-indigo-600 transform rotate-180' : 'bg-slate-100 text-slate-400'}`}
                                            >
                                                <FiChevronDown size={20} />
                                            </button>
                                        </div>
                                    </div>

                                    {/* Expanded Content */}
                                    {isExpanded && (
                                        <div className="p-6 bg-white border-t border-slate-50 space-y-8 animate-in slide-in-from-top-4 duration-300">
                                            {/* Direct Grades */}
                                            {stage.grades?.length > 0 && (
                                                <div className="space-y-3">
                                                    <div className="flex items-center gap-2 mb-2">
                                                        <span className="w-1 h-4 bg-indigo-500 rounded-full"></span>
                                                        <h4 className="text-sm font-bold text-slate-700 uppercase tracking-wide">الصفوف الدراسية (Direct Grades)</h4>
                                                    </div>
                                                    {stage.grades.map(grade => (
                                                        <GradeItem
                                                            key={grade.id}
                                                            grade={grade}
                                                            s={s}
                                                            data={data}
                                                            updateData={updateData}
                                                            bulkUpdate={bulkUpdate}
                                                            expandedGrades={expandedGrades}
                                                            setExpandedGrades={setExpandedGrades}
                                                            expandedClasses={expandedClasses}
                                                            setExpandedClasses={setExpandedClasses}
                                                            addCustomSubject={addCustomSubject}
                                                            removeCustomSubject={removeCustomSubject}
                                                        />
                                                    ))}
                                                </div>
                                            )}
                                            {/* Branches */}
                                            {stage.branches?.map(branch => (
                                                <div key={branch.id} className="space-y-3 pt-2">
                                                    <div className="flex items-center gap-2 mb-2">
                                                        <span className="w-1 h-4 bg-purple-500 rounded-full"></span>
                                                        <h4 className="text-sm font-bold text-slate-700 uppercase tracking-wide">مسار: <span className="text-purple-600">{branch.name}</span></h4>
                                                    </div>
                                                    {branch.grades?.map(grade => (
                                                        <GradeItem
                                                            key={grade.id}
                                                            grade={grade}
                                                            s={s}
                                                            data={data}
                                                            updateData={updateData}
                                                            bulkUpdate={bulkUpdate}
                                                            expandedGrades={expandedGrades}
                                                            setExpandedGrades={setExpandedGrades}
                                                            expandedClasses={expandedClasses}
                                                            setExpandedClasses={setExpandedClasses}
                                                            addCustomSubject={addCustomSubject}
                                                            removeCustomSubject={removeCustomSubject}
                                                        />
                                                    ))}
                                                </div>
                                            ))}
                                            {stage.grades?.length === 0 && stage.branches?.length === 0 && (
                                                <p className="text-center text-slate-400 italic py-4">قائمة فارغة</p>
                                            )}
                                        </div>
                                    )}
                                </div>
                            );
                        });
                    })()}
                </div>
            ) : (
                <div className="text-center py-12">
                    <p className="text-red-500 font-bold">فشل في تحميل هيكل النظام التعليمي</p>
                </div>
            )}
        </div>
    );
}

function GradeItem({ grade, s, data, updateData, bulkUpdate, expandedGrades, setExpandedGrades, expandedClasses, setExpandedClasses, addCustomSubject, removeCustomSubject }) {
    const isExpanded = expandedGrades[grade.id];
    // We check if the grade is effectively active by checking if ANY of its classes are active
    const isGradeActive = grade.classes?.some(cls => s.classes[cls.id]?.active);
    const [newSubject, setNewSubject] = useState('');
    const [isAdding, setIsAdding] = useState(false);
    const [error, setError] = useState('');

    const toggleGrade = (e) => {
        e.stopPropagation();
        const newState = !isGradeActive;
        // Prepare bulk update: Grade (Class) + All Subjects
        const updates = [];

        grade.classes?.forEach(cls => {
            updates.push({ type: 'class', id: cls.id, changes: { active: newState } });
            // Always update subjects to match the new state
            // If checking (true), check all subjects
            // If unchecking (false), uncheck all subjects
            cls.subjects?.forEach(sub => {
                updates.push({ type: 'subject', id: sub.id, changes: { active: newState } });
            });
        });

        bulkUpdate(updates);

        if (newState) setExpandedGrades({ ...expandedGrades, [grade.id]: true });
    };

    const allSubjects = [];
    const subjectsMap = new Map();
    grade.classes?.forEach(cls => {
        cls.subjects?.forEach(sub => {
            if (!subjectsMap.has(sub.name)) {
                subjectsMap.set(sub.name, sub);
                allSubjects.push(sub);
            }
        });
    });

    const customSubjects = s.customSubjects?.[grade.id] || [];

    const hasClasses = grade.classes && grade.classes.length > 0;
    const primaryClassId = grade.classes?.[0]?.id;
    const primaryClassConfig = primaryClassId ? (s.classes[primaryClassId] || { active: false, fees: 0, customName: '' }) : null;

    const handleAddSubject = () => {
        const name = newSubject.trim();
        if (!name) return;

        const isDuplicate =
            allSubjects.some(s => s.name === name) ||
            customSubjects.some(s => s.name === name);

        if (isDuplicate) {
            setError('موجود بالفعل');
            return;
        }

        addCustomSubject(grade.id, name);
        setNewSubject('');
        setError('');
        setIsAdding(false);
    };

    return (
        <div className={`rounded-xl overflow-hidden mb-3 transition-all duration-300 ${isGradeActive ? 'bg-white border border-indigo-200 shadow-md shadow-indigo-50' : 'bg-slate-50 border border-slate-200 opacity-80'}`}>
            <div
                className={`p-4 flex items-center justify-between cursor-pointer transition-colors ${isExpanded ? 'bg-indigo-50/20' : ''}`}
                onClick={() => setExpandedGrades({ ...expandedGrades, [grade.id]: !isExpanded })}
            >
                <div className="flex items-center gap-4">
                    <button
                        onClick={hasClasses ? toggleGrade : undefined}
                        className={`w-6 h-6 rounded-lg flex items-center justify-center transition-all duration-200 border ${!hasClasses ? 'bg-amber-100 border-amber-200 cursor-not-allowed' : (isGradeActive ? 'bg-indigo-600 border-indigo-600 text-white shadow-md shadow-indigo-200' : 'bg-white border-slate-300 text-slate-300 hover:border-indigo-400')}`}
                        title={!hasClasses ? "No classes defined" : "Toggle Grade"}
                    >
                        {!hasClasses ? <FiAlertCircle size={14} className="text-amber-500" /> : (isGradeActive ? <FiCheck size={14} /> : null)}
                    </button>
                    <span className={`font-bold text-base transition-colors ${isGradeActive ? 'text-indigo-900' : 'text-slate-500'}`}>{grade.name}</span>
                </div>

                <div className="flex items-center gap-3">
                    <div className="flex items-center gap-2">
                        <span className={`text-[10px] px-2 py-1 rounded-md font-bold ${isGradeActive ? 'bg-indigo-100 text-indigo-700' : 'bg-slate-200 text-slate-500'}`}>{allSubjects.length + customSubjects.length} مواد</span>
                    </div>
                    <button className={`w-6 h-6 flex items-center justify-center rounded-full transition-transform duration-300 ${isExpanded ? 'rotate-180 text-indigo-500' : 'text-slate-400'}`}>
                        <FiChevronDown size={18} />
                    </button>
                </div>
            </div>

            {isExpanded && (
                <div className="px-4 pb-4 bg-white/50 space-y-6 pt-2">
                    {!hasClasses && (
                        <div className="flex flex-col items-center justify-center py-4 bg-amber-50/50 rounded-xl border border-amber-100/50 mt-2">
                            <FiAlertCircle className="text-amber-500 mb-2" size={24} />
                            <p className="text-xs font-bold text-amber-700">تنبيه: لا توجد فصول دراسية</p>
                            <p className="text-[10px] text-amber-600 mt-1">يرجى إضافة فصل افتراضي في لوحة التحكم</p>
                        </div>
                    )}

                    {/* Grade Settings Section (Custom Name & Age) */}
                    {primaryClassConfig && (
                        <div className={`mt-2 flex flex-col md:flex-row md:items-center gap-4 p-4 rounded-xl border transition-all duration-300 ${primaryClassConfig.active ? 'bg-indigo-50 border-indigo-100 shadow-sm' : 'bg-slate-50 border-slate-100 opacity-60 grayscale'}`}>
                            <div className="flex items-center gap-2 min-w-[120px]">
                                <FiSettings className={primaryClassConfig.active ? "text-indigo-500" : "text-slate-400"} />
                                <span className={`text-xs font-bold ${primaryClassConfig.active ? 'text-indigo-900' : 'text-slate-500'}`}>إعدادات الصف</span>
                            </div>

                            <div className="flex flex-wrap gap-3 flex-1">
                                <div className="relative group w-32">
                                    <div className="absolute inset-y-0 right-3 flex items-center pointer-events-none">
                                        <span className="text-[10px] font-bold text-slate-400">السن</span>
                                    </div>
                                    <input
                                        type="number"
                                        step="0.1"
                                        placeholder="السن"
                                        value={data.ageRequirement?.[grade.id] ?? grade.acceptedAge ?? 0}
                                        onChange={e => {
                                            const ageReq = { ...(data.ageRequirement || {}) };
                                            const val = e.target.value === '' ? '' : parseFloat(e.target.value);
                                            ageReq[grade.id] = val;
                                            updateData({ ageRequirement: ageReq });
                                        }}
                                        className="w-full px-4 py-2 pr-9 border border-slate-200 rounded-lg text-xs outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all shadow-sm bg-white text-center"
                                        title="السن المطلوب للصف (بالسنوات في 1 أكتوبر)"
                                    />
                                </div>

                                <div className="relative group flex-1">
                                    <input
                                        type="text"
                                        placeholder="اسم مخصص للصف (مثل: 1/أ أو KG1 - Blue)"
                                        value={primaryClassConfig.customName || ''}
                                        onChange={e => bulkUpdate([{ type: 'class', id: primaryClassId, changes: { customName: e.target.value, active: true } }])}
                                        className="w-full px-4 py-2 border border-slate-200 rounded-lg text-xs outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all shadow-sm bg-white"
                                    />
                                </div>
                            </div>
                        </div>
                    )}

                    {/* Subjects Section */}
                    {(allSubjects.length > 0 || isGradeActive) && (
                        <div className="space-y-3">
                            <div className="flex items-center gap-2 text-indigo-900/80 pb-1 border-b border-indigo-50">
                                <FiBook size={14} />
                                <h5 className="text-xs font-bold uppercase tracking-wider">المواد الدراسية المقررة</h5>
                            </div>
                            <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
                                {/* System Subjects */}
                                {allSubjects.map(sub => {
                                    const subConfig = s.subjects[sub.id] || { active: false };
                                    return (
                                        <div key={sub.id} className={`group relative flex flex-col p-3 border rounded-xl transition-all duration-200 ${isGradeActive ? 'bg-white border-indigo-200 shadow-sm' : 'bg-slate-50 border-slate-100 opacity-60'}`}>
                                            <div className="flex items-center gap-2 mb-2">
                                                <div className={`w-2 h-2 rounded-full ${isGradeActive ? 'bg-indigo-500' : 'bg-slate-300'}`}></div>
                                                <span className={`text-xs font-bold leading-tight flex-1 ${isGradeActive ? 'text-slate-700' : 'text-slate-500'}`}>{sub.name}</span>
                                            </div>

                                            {isGradeActive && (
                                                <input
                                                    type="text"
                                                    placeholder="مسمى مخصص..."
                                                    value={subConfig.customName || ''}
                                                    onChange={e => bulkUpdate([{ type: 'subject', id: sub.id, changes: { customName: e.target.value } }])}
                                                    className="w-full mt-auto px-2 py-1 text-[10px] border border-slate-200 rounded bg-slate-50 outline-none focus:ring-1 focus:ring-indigo-400 focus:bg-white transition-all"
                                                />
                                            )}
                                        </div>
                                    );
                                })}

                                {/* Custom Subjects */}
                                {customSubjects.map(sub => (
                                    <div key={sub.id} className="group relative flex flex-col p-3 border border-indigo-200 bg-indigo-50/20 rounded-xl shadow-sm">
                                        <div className="flex items-center justify-between mb-2">
                                            <div className="flex items-center gap-2">
                                                <div className="w-2 h-2 rounded-full bg-purple-500"></div>
                                                <span className="text-xs font-bold leading-tight flex-1 text-slate-700">{sub.name}</span>
                                            </div>
                                            <button
                                                onClick={() => removeCustomSubject(grade.id, sub.id)}
                                                className="opacity-0 group-hover:opacity-100 transition-opacity text-red-400 hover:text-red-500 p-1"
                                            >
                                                <FiTrash2 size={12} />
                                            </button>
                                        </div>
                                        <span className="text-[9px] text-purple-600 bg-purple-100 w-fit px-1.5 py-0.5 rounded">مادة إضافية</span>
                                    </div>
                                ))}

                                {/* Add New Subject */}
                                {isGradeActive && (
                                    isAdding ? (
                                        <div className="border border-indigo-300 bg-white rounded-xl p-3 flex flex-col gap-2 shadow-sm animate-in fade-in zoom-in-95">
                                            <input
                                                type="text"
                                                autoFocus
                                                placeholder="اسم المادة..."
                                                className={`text-xs p-2 border rounded-lg outline-none transition-colors ${error ? 'border-red-300 bg-red-50 focus:border-red-500' : 'border-slate-200 focus:border-indigo-500'}`}
                                                value={newSubject}
                                                onChange={e => { setNewSubject(e.target.value); setError(''); }}
                                                onKeyDown={e => {
                                                    if (e.key === 'Enter') handleAddSubject();
                                                    if (e.key === 'Escape') setIsAdding(false);
                                                }}
                                            />
                                            {error && <span className="text-[9px] text-red-500 font-bold px-1 animate-in zoom-in">{error}</span>}
                                            <div className="flex gap-2">
                                                <button
                                                    onClick={handleAddSubject}
                                                    className="flex-1 bg-indigo-600 text-white text-[10px] py-1.5 rounded-lg hover:bg-indigo-700 font-bold"
                                                >
                                                    إضافة
                                                </button>
                                                <button
                                                    onClick={() => setIsAdding(false)}
                                                    className="px-2 bg-slate-100 text-slate-500 text-[10px] py-1.5 rounded-lg hover:bg-slate-200"
                                                >
                                                    إلغاء
                                                </button>
                                            </div>
                                        </div>
                                    ) : (
                                        <button
                                            onClick={() => setIsAdding(true)}
                                            className="border border-dashed border-indigo-200 bg-indigo-50/30 rounded-xl p-3 flex flex-col justify-center items-center gap-2 hover:bg-indigo-50 transition-colors cursor-pointer text-indigo-400 hover:text-indigo-600 h-[86px]"
                                        >
                                            <div className="w-8 h-8 rounded-full bg-white border border-indigo-100 flex items-center justify-center shadow-sm group-hover:scale-110 transition-transform">
                                                <FiPlus size={16} />
                                            </div>
                                            <span className="text-[10px] font-bold">إضافة مادة</span>
                                        </button>
                                    )
                                )}
                            </div>
                        </div>
                    )}

                    {/* Extra Classes Section */}
                    {isGradeActive && grade.classes?.length > 1 && (
                        <div className="space-y-3 border-t border-slate-100 pt-4 mt-2">
                            <div className="flex items-center gap-2 text-indigo-900/70">
                                <FiLayers size={14} />
                                <h5 className="text-xs font-bold uppercase tracking-wider">الفصول / المجموعات الدراسية الإضافية</h5>
                            </div>
                            <div className="space-y-2">
                                {grade.classes?.slice(1).map(cls => renderClass(cls, s, bulkUpdate, expandedClasses, setExpandedClasses))}
                            </div>
                        </div>
                    )}
                </div>
            )}
        </div>
    );
}

function renderClass(cls, s, bulkUpdate, expandedClasses, setExpandedClasses) {
    const config = s.classes[cls.id] || { active: false };

    return (
        <div key={cls.id} className={`border rounded-xl  overflow-hidden transition-all duration-200 ${config.active ? 'bg-white border-indigo-200 shadow-sm' : 'bg-slate-50 border-slate-100 opacity-60'}`}>
            <div className={`p-3 flex items-center justify-between`}>
                <div className="flex items-center gap-3 flex-1">
                    <button
                        onClick={() => bulkUpdate([{ type: 'class', id: cls.id, changes: { active: !config.active } }])}
                        className={`w-5 h-5 rounded-md flex items-center justify-center transition-colors border ${config.active ? 'bg-indigo-500 border-indigo-500 text-white' : 'bg-white border-slate-300 text-slate-200'}`}
                    >
                        {config.active ? <FiCheck size={12} /> : null}
                    </button>
                    <div className="flex-1">
                        <span className={`text-xs font-bold ${config.active ? 'text-slate-800' : 'text-slate-500'}`}>{cls.name}</span>
                    </div>
                </div>

                {config.active && (
                    <div className="flex items-center gap-3 animate-in fade-in slide-in-from-left-2">

                        <input
                            type="text"
                            placeholder="اسم مخصص (مثال: 1/أ)"
                            value={config.customName || ''}
                            onChange={e => bulkUpdate([{ type: 'class', id: cls.id, changes: { customName: e.target.value } }])}
                            className="px-3 py-1.5 border border-slate-200 rounded-lg text-xs w-32 outline-none focus:ring-2 focus:ring-indigo-500 transition-all shadow-sm"
                        />
                    </div>
                )}
            </div>
        </div>
    );
}
