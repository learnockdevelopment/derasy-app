import { useState } from 'react';
import { FiUser, FiShield, FiPlus, FiTrash2, FiBriefcase } from 'react-icons/fi';

export default function StepAccounts({ data, updateData }) {
    const [isAdding, setIsAdding] = useState(false);
    const [newUser, setNewUser] = useState({
        name: '',
        email: '',
        phone: '',
        password: '',
        role: 'Manager'
    });

    const roles = [
        { id: 'Manager', label: 'مدير (Manager)' },
        { id: 'Accountant', label: 'محاسب (Accountant)' },
        { id: 'Admin', label: 'مسؤول (Admin)' },
        { id: 'Teacher', label: 'معلم (Teacher)' }
    ];

    const handleAddUser = () => {
        if (!newUser.name || !newUser.email || !newUser.password) return;

        const updatedUsers = [...(data.customUsers || []), { ...newUser, id: Date.now() }];
        updateData('customUsers', updatedUsers);

        setNewUser({ name: '', email: '', phone: '', password: '', role: 'Manager' });
        setIsAdding(false);
    };

    const removeUser = (index) => {
        const updatedUsers = [...(data.customUsers || [])];
        updatedUsers.splice(index, 1);
        updateData('customUsers', updatedUsers);
    };

    const renderUserForm = (title, type, userData, icon, isReadOnly = false) => (
        <div className="bg-gray-50 rounded-2xl p-6 border border-gray-100 hover:border-blue-200 transition-colors h-full">
            <div className="flex items-center gap-3 mb-4 pb-3 border-b border-gray-200">
                <div className={`p-2 rounded-lg ${type === 'ownerData' ? 'bg-purple-100 text-purple-600' : 'bg-orange-100 text-orange-600'}`}>
                    {icon}
                </div>
                <h3 className="font-bold text-gray-800">{title}</h3>
            </div>

            <div className="space-y-4">
                <div>
                    <label className="block text-xs font-bold text-gray-500 mb-1">الاسم الكامل</label>
                    <input
                        type="text"
                        value={userData.name}
                        onChange={(e) => updateData(type, { ...userData, name: e.target.value })}
                        className="w-full px-3 py-2 rounded-lg border border-gray-200 focus:border-blue-500 outline-none transition-all focus:ring-2 focus:ring-blue-100"
                    />
                </div>
                <div>
                    <label className="block text-xs font-bold text-gray-500 mb-1">البريد الإلكتروني</label>
                    <input
                        type="email"
                        value={userData.email}
                        onChange={(e) => updateData(type, { ...userData, email: e.target.value })}
                        className="w-full px-3 py-2 rounded-lg border border-gray-200 focus:border-blue-500 outline-none dir-ltr text-left transition-all focus:ring-2 focus:ring-blue-100"
                    />
                </div>
                <div>
                    <label className="block text-xs font-bold text-gray-500 mb-1">رقم الهاتف</label>
                    <input
                        type="tel"
                        value={userData.phone}
                        onChange={(e) => updateData(type, { ...userData, phone: e.target.value })}
                        className="w-full px-3 py-2 rounded-lg border border-gray-200 focus:border-blue-500 outline-none dir-ltr text-left transition-all focus:ring-2 focus:ring-blue-100"
                    />
                </div>
                <div>
                    <label className="block text-xs font-bold text-gray-500 mb-1">كلمة المرور</label>
                    <input
                        type="password"
                        value={userData.password}
                        onChange={(e) => updateData(type, { ...userData, password: e.target.value })}
                        className="w-full px-3 py-2 rounded-lg border border-gray-200 focus:border-blue-500 outline-none dir-ltr text-left transition-all focus:ring-2 focus:ring-blue-100"
                    />
                </div>
            </div>
        </div>
    );

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-right-8 duration-500">
            {/* Headers */}
            <div className="flex items-center gap-4 mb-2">
                <div className="p-3 bg-indigo-100 text-indigo-600 rounded-xl">
                    <FiUser size={24} />
                </div>
                <div>
                    <h2 className="text-xl font-bold text-gray-800">حسابات الإدارة</h2>
                    <p className="text-gray-500 text-sm">سيتم إنشاء الحسابات تلقائياً أو ربطها في حال وجودها</p>
                </div>
            </div>

            {/* Main Accounts Grid */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {renderUserForm('بيانات مالك المدرسة', 'ownerData', data.owner, <FiUser size={20} />)}
                {renderUserForm('بيانات المشرف (Moderator)', 'moderatorData', data.moderator, <FiShield size={20} />)}
            </div>

            {/* Divider */}
            <div className="border-t border-gray-100 my-6"></div>

            {/* Extra Users Section */}
            <div className="space-y-6">
                <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                        <div className="p-2 bg-teal-100 text-teal-600 rounded-lg">
                            <FiBriefcase size={20} />
                        </div>
                        <div>
                            <h3 className="font-bold text-gray-800">مستخدمين إضافيين</h3>
                            <p className="text-xs text-gray-500">Add other roles (Employees, Managers, etc.)</p>
                        </div>
                    </div>
                    {!isAdding && (
                        <button
                            onClick={() => setIsAdding(true)}
                            className="flex items-center gap-2 px-4 py-2 bg-teal-50 text-teal-600 rounded-xl hover:bg-teal-100 transition-colors text-sm font-bold"
                        >
                            <FiPlus /> إضافة مستخدم
                        </button>
                    )}
                </div>

                {/* List of Custom Users */}
                {(data.customUsers && data.customUsers.length > 0) && (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                        {data.customUsers.map((user, idx) => (
                            <div key={idx} className="bg-white border border-gray-200 rounded-xl p-4 flex flex-col gap-3 group relative hover:border-teal-200 hover:shadow-sm transition-all">
                                <button
                                    onClick={() => removeUser(idx)}
                                    className="absolute top-3 left-3 text-gray-300 hover:text-red-500 transition-colors"
                                >
                                    <FiTrash2 size={16} />
                                </button>

                                <div className="flex items-center gap-3">
                                    <div className="w-10 h-10 rounded-full bg-teal-50 text-teal-600 flex items-center justify-center font-bold text-lg">
                                        {user.name.charAt(0).toUpperCase()}
                                    </div>
                                    <div>
                                        <h4 className="font-bold text-gray-800 text-sm">{user.name}</h4>
                                        <span className="text-[10px] bg-teal-100 text-teal-700 px-2 py-0.5 rounded-full">{user.role}</span>
                                    </div>
                                </div>
                                <div className="text-xs text-gray-500 space-y-1">
                                    <p className="flex items-center gap-2 truncate" title={user.email}>
                                        <span className="font-bold">@</span> {user.email}
                                    </p>
                                    <p className="flex items-center gap-2">
                                        <span className="font-bold">#</span> {user.phone}
                                    </p>
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {/* Add User Form */}
                {isAdding && (
                    <div className="bg-teal-50/50 border border-teal-100 rounded-xl p-6 animate-in fade-in slide-in-from-top-4">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div>
                                <label className="block text-xs font-bold text-gray-500 mb-1">الاسم الكامل</label>
                                <input
                                    type="text"
                                    className="w-full px-3 py-2 rounded-lg border border-gray-200 focus:border-teal-500 outline-none bg-white"
                                    value={newUser.name}
                                    onChange={e => setNewUser({ ...newUser, name: e.target.value })}
                                />
                            </div>
                            <div>
                                <label className="block text-xs font-bold text-gray-500 mb-1">البريد الإلكتروني</label>
                                <input
                                    type="email"
                                    className="w-full px-3 py-2 rounded-lg border border-gray-200 focus:border-teal-500 outline-none bg-white dir-ltr text-left"
                                    value={newUser.email}
                                    onChange={e => setNewUser({ ...newUser, email: e.target.value })}
                                />
                            </div>
                            <div>
                                <label className="block text-xs font-bold text-gray-500 mb-1">رقم الهاتف</label>
                                <input
                                    type="tel"
                                    className="w-full px-3 py-2 rounded-lg border border-gray-200 focus:border-teal-500 outline-none bg-white dir-ltr text-left"
                                    value={newUser.phone}
                                    onChange={e => setNewUser({ ...newUser, phone: e.target.value })}
                                />
                            </div>
                            <div>
                                <label className="block text-xs font-bold text-gray-500 mb-1">كلمة المرور</label>
                                <input
                                    type="password"
                                    className="w-full px-3 py-2 rounded-lg border border-gray-200 focus:border-teal-500 outline-none bg-white dir-ltr text-left"
                                    value={newUser.password}
                                    onChange={e => setNewUser({ ...newUser, password: e.target.value })}
                                />
                            </div>
                            <div className="md:col-span-2">
                                <label className="block text-xs font-bold text-gray-500 mb-1">الدور (Role)</label>
                                <div className="flex flex-wrap gap-2">
                                    {roles.map(role => (
                                        <button
                                            key={role.id}
                                            onClick={() => setNewUser({ ...newUser, role: role.id })}
                                            className={`px-4 py-2 rounded-lg text-sm font-bold border transition-all ${newUser.role === role.id
                                                    ? 'bg-teal-600 text-white border-teal-600 shadow-md'
                                                    : 'bg-white text-gray-500 border-gray-200 hover:border-teal-300'
                                                }`}
                                        >
                                            {role.label}
                                        </button>
                                    ))}
                                </div>
                            </div>
                        </div>
                        <div className="flex gap-3 mt-6">
                            <button
                                onClick={handleAddUser}
                                className="px-6 py-2 bg-teal-600 text-white rounded-lg font-bold hover:bg-teal-700 transition-colors shadow-sm"
                            >
                                حفظ وإضافة
                            </button>
                            <button
                                onClick={() => setIsAdding(false)}
                                className="px-6 py-2 bg-white text-gray-500 border border-gray-200 rounded-lg font-bold hover:bg-gray-50 transition-colors"
                            >
                                إلغاء
                            </button>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}
