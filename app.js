// Student Data Manager
const STORAGE_KEY = 'shinsedaikan_data';
const WEIGHTS = { technique: 0.5, etiquette: 0.3, attendance: 0.2 };

let students = loadData();

function loadData() {
    const data = localStorage.getItem(STORAGE_KEY);
    return data ? JSON.parse(data) : [
        { name: "Takeshi Kovacs", technique: 85, etiquette: 90, kiai: 80, attendance: 45, belt: "Green", mainTech: "Ikkyo", avatar: null },
        { name: "Satoshi Nakamoto", technique: 95, etiquette: 70, kiai: 85, attendance: 30, belt: "Yellow", mainTech: "Tai no Henko", avatar: null }
    ];
}

function saveData() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(students));
}

// DOM Elements
const splash = document.getElementById('splash');
const dashboard = document.getElementById('dashboard');
const studentList = document.getElementById('student-list');
const modal = document.getElementById('modal');
const studentForm = document.getElementById('student-form');
const photoInput = document.getElementById('student-photo');
const photoPreview = document.getElementById('photo-preview');
const readerContainer = document.getElementById('reader-container');
let html5QrCode;
let charts = {};

// Splash Logic
function runSplash() {
    let progress = 0;
    const interval = setInterval(() => {
        progress += 20;
        if (progress >= 100) {
            clearInterval(interval);
            setTimeout(hideSplash, 400);
        }
        document.getElementById('splash-progress').style.width = `${progress}%`;
        document.getElementById('splash-percent').innerText = `${progress}%`;
    }, 150);
}

function hideSplash() {
    splash.classList.add('opacity-0');
    setTimeout(() => {
        splash.style.display = 'none';
        dashboard.classList.remove('hidden');
        setTimeout(() => dashboard.classList.remove('opacity-0'), 50);
        renderStudents();
    }, 1000);
}

// Rendering
function renderStudents() {
    studentList.innerHTML = '';
    students.forEach((student, index) => {
        const score = (student.technique * WEIGHTS.technique) + (student.etiquette * WEIGHTS.etiquette) + (student.attendance * 0.1 * WEIGHTS.attendance); // Attendance normalized for display
        const card = document.createElement('div');
        card.id = `student-${index}`;
        card.className = 'student-card rounded-lg p-6 flex flex-col md:flex-row md:items-center justify-between gap-6';
        
        card.innerHTML = `
            <div class="flex items-center gap-6 flex-1">
                <div class="relative">
                    ${student.avatar ? `<img src="${student.avatar}" class="student-avatar">` : `<div class="student-avatar bg-primary/20 flex items-center justify-center text-primary font-bold text-xl">${student.name[0]}</div>`}
                    <div class="absolute -bottom-1 -right-1 belt-badge belt-${student.belt.toLowerCase()}">${student.belt}</div>
                </div>
                <div>
                    <h3 class="text-xl font-bold uppercase tracking-wider mb-1">${student.name}</h3>
                    <p class="text-[10px] text-slate-500 uppercase tracking-widest mb-3">Mastering: <span class="text-slate-300">${student.mainTech}</span></p>
                    <div class="flex flex-wrap gap-2">
                        <span class="text-[9px] bg-white/5 border border-white/10 px-2 py-1 rounded text-slate-400">WAZA: <span class="text-primary">${student.technique}</span></span>
                        <span class="text-[9px] bg-white/5 border border-white/10 px-2 py-1 rounded text-slate-400">REIGI: <span class="text-primary">${student.etiquette}</span></span>
                        <span class="text-[9px] bg-white/5 border border-white/10 px-2 py-1 rounded text-slate-400">KIAI: <span class="text-primary font-bold">${student.kiai || 50}</span></span>
                        <span class="text-[9px] bg-white/5 border border-white/10 px-2 py-1 rounded text-slate-400">ATT: <span class="text-primary font-bold">${student.attendance}</span></span>
                    </div>
                </div>
            </div>
            <div class="flex items-center gap-8">
                <div class="radar-container hidden md:block">
                    <canvas id="chart-${index}"></canvas>
                </div>
                <div class="maut-badge flex flex-col items-end min-w-[100px]">
                    <span class="text-[10px] uppercase tracking-[0.2em] text-slate-500 font-bold mb-1">MAUT Score</span>
                    <span class="text-4xl font-bold text-primary tracking-tighter">${score.toFixed(1)}</span>
                </div>
            </div>
        `;
        studentList.appendChild(card);
        initChart(index, student);
    });
}

function initChart(index, s) {
    const ctx = document.getElementById(`chart-${index}`).getContext('2d');
    if (charts[index]) charts[index].destroy();
    
    charts[index] = new Chart(ctx, {
        type: 'radar',
        data: {
            labels: ['Waza', 'Reigi', 'Kiai', 'Attendance'],
            datasets: [{
                data: [s.technique, s.etiquette, s.kiai || 50, Math.min(s.attendance * 2, 100)],
                backgroundColor: 'rgba(153, 0, 0, 0.2)',
                borderColor: '#990000',
                borderWidth: 2,
                pointRadius: 0
            }]
        },
        options: {
            scales: {
                r: {
                    min: 0,
                    max: 100,
                    ticks: { display: false },
                    grid: { color: 'rgba(255,255,255,0.05)' },
                    angleLines: { color: 'rgba(255,255,255,0.05)' },
                    pointLabels: { display: false }
                }
            },
            plugins: { legend: { display: false } }
        }
    });
}

// Photo Preview
let currentAvatarData = null;
photoInput.onchange = (e) => {
    const file = e.target.files[0];
    if (file) {
        const reader = new FileReader();
        reader.onload = (ev) => {
            currentAvatarData = ev.target.result;
            photoPreview.innerHTML = `<img src="${currentAvatarData}">`;
        };
        reader.readAsDataURL(file);
    }
};

// Interaction logic
document.getElementById('add-student-btn').onclick = () => modal.classList.remove('hidden');
document.getElementById('close-modal').onclick = () => modal.classList.add('hidden');

studentForm.onsubmit = (e) => {
    e.preventDefault();
    const student = {
        name: document.getElementById('student-name').value,
        belt: document.getElementById('student-belt').value,
        mainTech: document.getElementById('student-technique').value,
        technique: parseInt(document.getElementById('tech-score').value),
        etiquette: parseInt(document.getElementById('eti-score').value),
        kiai: parseInt(document.getElementById('kiai-score').value),
        attendance: parseInt(document.getElementById('att-score').value),
        avatar: currentAvatarData
    };
    
    students.unshift(student);
    saveData();
    renderStudents();
    modal.classList.add('hidden');
    studentForm.reset();
    photoPreview.innerHTML = `<span class="material-symbols-outlined text-slate-500">add_a_photo</span>`;
    currentAvatarData = null;
};

// QR Attendance
document.getElementById('scan-btn').onclick = () => {
    readerContainer.classList.remove('hidden');
    html5QrCode = new Html5Qrcode("reader");
    html5QrCode.start(
        { facingMode: "environment" },
        { fps: 10, qrbox: { width: 250, height: 250 } },
        (decodedText) => {
            handleAttendance(decodedText);
            html5QrCode.stop().then(() => readerContainer.classList.add('hidden'));
        },
        () => {}
    );
};

document.getElementById('stop-scan').onclick = () => {
    if (html5QrCode) html5QrCode.stop().then(() => readerContainer.classList.add('hidden'));
};

function handleAttendance(name) {
    const idx = students.findIndex(s => s.name.toLowerCase() === name.toLowerCase());
    if (idx !== -1) {
        students[idx].attendance += 1;
        saveData();
        renderStudents();
        const card = document.getElementById(`student-${idx}`);
        card.classList.add('attendance-ping');
        setTimeout(() => card.classList.remove('attendance-ping'), 2000);
    } else {
        alert("Student not found!");
    }
}

// Live Sliders
['tech', 'eti', 'kiai', 'att'].forEach(key => {
    const input = document.getElementById(`${key}-score`);
    const display = document.getElementById(`val-${key}`);
    input.oninput = () => display.innerText = input.value;
});

window.onload = runSplash;
