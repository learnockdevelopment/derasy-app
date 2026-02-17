'use client';

import { useEffect, useRef, useState, useCallback } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { FiTarget } from 'react-icons/fi';

export default function MapPicker({ lat, lng, onLocationChange }) {
    const mapRef = useRef(null);
    const containerRef = useRef(null);
    const markerRef = useRef(null);
    const [isClient, setIsClient] = useState(false);
    const [isGeocoding, setIsGeocoding] = useState(false);

    useEffect(() => {
        setIsClient(true);
    }, []);

    const fetchAddress = async (latitude, longitude) => {
        setIsGeocoding(true);
        try {
            const response = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&accept-language=ar`);
            const data = await response.json();
            if (data && data.display_name) {
                return data.display_name;
            }
        } catch (error) {
            console.error("Geocoding failed:", error);
        } finally {
            setIsGeocoding(false);
        }
        return null;
    };

    const initializeMap = useCallback(() => {
        if (!containerRef.current || mapRef.current) return;

        // Setup icons
        delete L.Icon.Default.prototype._getIconUrl;
        L.Icon.Default.mergeOptions({
            iconUrl: 'https://unpkg.com/leaflet@1.9.3/dist/images/marker-icon.png',
            shadowUrl: 'https://unpkg.com/leaflet@1.9.3/dist/images/marker-shadow.png',
        });

        const initialLat = lat || 30.0444;
        const initialLng = lng || 31.2357;

        // Create map instance manually
        const map = L.map(containerRef.current, {
            center: [initialLat, initialLng],
            zoom: 13,
            scrollWheelZoom: false,
            zoomControl: false // We'll keep it clean
        });

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; OpenStreetMap contributors'
        }).addTo(map);

        // Add Zoom Control at a better position
        L.control.zoom({ position: 'topright' }).addTo(map);

        const marker = L.marker([initialLat, initialLng]).addTo(map);

        map.on('click', async (e) => {
            const { lat: clickLat, lng: clickLng } = e.latlng;
            marker.setLatLng([clickLat, clickLng]);
            const address = await fetchAddress(clickLat, clickLng);
            onLocationChange({ lat: clickLat, lng: clickLng }, address);
        });

        mapRef.current = map;
        markerRef.current = marker;
    }, [lat, lng, onLocationChange]);

    useEffect(() => {
        if (isClient) {
            // Small timeout to ensure the div is fully rendered
            const timer = setTimeout(initializeMap, 100);
            return () => {
                clearTimeout(timer);
                if (mapRef.current) {
                    mapRef.current.off();
                    mapRef.current.remove();
                    mapRef.current = null;
                }
            };
        }
    }, [isClient, initializeMap]);

    // Handle updates to lat/lng from parent (e.g. from "Get Location")
    useEffect(() => {
        if (mapRef.current && markerRef.current && lat && lng) {
            const currentPos = markerRef.current.getLatLng();
            if (currentPos.lat !== lat || currentPos.lng !== lng) {
                markerRef.current.setLatLng([lat, lng]);
                mapRef.current.flyTo([lat, lng], mapRef.current.getZoom(), { animate: true });
            }
        }
    }, [lat, lng]);

    const handleGetCurrentLocation = () => {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                async (position) => {
                    const { latitude, longitude } = position.coords;
                    const address = await fetchAddress(latitude, longitude);
                    onLocationChange({ lat: latitude, lng: longitude }, address);
                },
                (error) => {
                    console.error("Error getting location:", error);
                    alert("تعذر الحصول على موقعك الحالي. يرجى التأكد من تفعيل أذونات الموقع.");
                }
            );
        }
    };

    if (!isClient) return <div className="h-[300px] w-full bg-slate-50 rounded-2xl animate-pulse" />;

    return (
        <div className="relative w-full h-[300px] rounded-2xl overflow-hidden border-2 border-slate-200 group">
            <div
                ref={containerRef}
                style={{ height: '100%', width: '100%', background: '#f8fafc' }}
            />

            {/* Overlay button for current location */}
            <button
                type="button"
                onClick={handleGetCurrentLocation}
                disabled={isGeocoding}
                className="absolute bottom-4 right-4 z-[1000] bg-white p-3 rounded-full shadow-lg border border-slate-200 text-blue-600 hover:bg-blue-50 transition-all hover:scale-110 active:scale-95 flex items-center justify-center disabled:opacity-50 disabled:cursor-not-allowed"
                title="تحديد موقعي الحالي"
            >
                {isGeocoding ? (
                    <div className="w-5 h-5 border-2 border-blue-600 border-t-transparent rounded-full animate-spin"></div>
                ) : (
                    <FiTarget size={20} />
                )}
            </button>

            {(isGeocoding || !lat) && (
                <div className="absolute inset-x-0 top-4 z-[1000] pointer-events-none flex justify-center">
                    <span className="bg-white/90 backdrop-blur-sm px-4 py-1.5 rounded-full text-[10px] font-bold text-slate-500 border border-slate-200 shadow-sm">
                        {isGeocoding ? "جاري استخراج العنوان..." : "انقر على الخريطة لتحديد الموقع"}
                    </span>
                </div>
            )}
        </div>
    );
}
