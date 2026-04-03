// Student Data Manager
const STORAGE_KEY = 'shinsedaikan_data_v2';
const WEIGHTS = { technique: 0.5, etiquette: 0.3, attendance: 0.2 };

let students = loadData();
let html5QrCode = null;
let editingId = null;

function loadData() {
    const dataV2 = localStorage.getItem(STORAGE_KEY);
    if (dataV2) return JSON.parse(dataV2);

    // Migration from v1
    const dataV1 = localStorage.getItem('shinsedaikan_data');
    if (dataV1) {
        try {
            const oldData = JSON.parse(dataV1);
            // Ensure old data structure matches v2 if necessary
            // (In this case, the main change is the score calculation logic, not the storage object schema)
            localStorage.setItem(STORAGE_KEY, JSON.stringify(oldData));
            return oldData;
        } catch (e) {
            console.error("Migration failed", e);
        }
    }

    // Default initial data
    return [
        { id: '1', name: "Takeshi Kovacs", technique: 85, etiquette: 90, attendance: 45, belt: "Green", mainTech: "Ikkyo", avatar: null },
        { id: '2', name: "Satoshi Nakamoto", technique: 95, etiquette: 70, attendance: 30, belt: "Yellow", mainTech: "Tai no Henko", avatar: null }
    ];
}

function saveData() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(students));
}

// DOM Elements
const studentList = document.getElementById('student-list');
const registrationModal = document.getElementById('registration-modal');
const studentForm = document.getElementById('student-form');
const searchInput = document.getElementById('search-input');
const beltFilter = document.getElementById('belt-filter');
const emptyState = document.getElementById('empty-state');

// Initial Render
function renderStudents() {
    const searchTerm = searchInput.value.toLowerCase();
    const filterValue = beltFilter.value;

    studentList.innerHTML = '';
    let visibleCount = 0;

    students.forEach((student) => {
        const matchesSearch = student.name.toLowerCase().includes(searchTerm);
        const matchesBelt = filterValue === 'all' || student.belt === filterValue;

        if (matchesSearch && matchesBelt) {
            visibleCount++;
            const score = calculateMAUT(student);
            const card = createStudentCard(student, score);
            studentList.appendChild(card);
        }
    });

    emptyState.classList.toggle('hidden', visibleCount > 0);
}

function calculateMAUT(s) {
    return (s.technique * WEIGHTS.technique) +
           (s.etiquette * WEIGHTS.etiquette) +
           (s.attendance * WEIGHTS.attendance);
}

function createStudentCard(student, score) {
    const div = document.createElement('div');
    div.className = 'student-card bg-[#1a1a1a] p-8 rounded-2xl border border-gray-800 flex flex-col md:flex-row items-center justify-between gap-8 animate-modal-in group';

    div.innerHTML = `
        <div class="flex items-center gap-8 flex-1 w-full">
            <div class="relative">
                <div class="w-20 h-20 bg-slate-800 rounded-full flex items-center justify-center text-red-600 font-black text-2xl border-2 border-gray-700 shadow-xl overflow-hidden">
                    ${student.avatar ? `<img src="${student.avatar}" class="w-full h-full object-cover">` : student.name[0]}
                </div>
                <div class="absolute -bottom-2 -right-2 px-3 py-1 rounded-full text-[9px] font-black uppercase tracking-tighter shadow-lg border border-black/20 belt-${student.belt.toLowerCase()}">
                    ${student.belt}
                </div>
            </div>
            <div class="flex-1">
                <div class="flex items-center gap-3 mb-2">
                    <h3 class="text-xl font-bold text-white uppercase tracking-tight">${student.name}</h3>
                    <span class="text-[8px] bg-red-600/10 text-red-500 px-2 py-0.5 rounded-full font-bold uppercase tracking-widest border border-red-600/20">Active</span>
                </div>
                <p class="text-[10px] text-gray-500 uppercase tracking-[0.2em] mb-4 font-semibold">Tokui Waza: <span class="text-gray-300 font-bold">${student.mainTech}</span></p>
                <div class="grid grid-cols-4 gap-4 max-w-xs">
                    <div>
                        <p class="text-[8px] text-gray-600 font-black uppercase">Waza</p>
                        <p class="text-xs font-bold text-white">${student.technique}</p>
                    </div>
                    <div>
                        <p class="text-[8px] text-gray-600 font-black uppercase">Reigi</p>
                        <p class="text-xs font-bold text-white">${student.etiquette}</p>
                    </div>
                    <div>
                        <p class="text-[8px] text-gray-600 font-black uppercase">Atten</p>
                        <p class="text-xs font-bold text-white">${student.attendance}</p>
                    </div>
                </div>
            </div>
        </div>

        <div class="flex items-center gap-10 w-full md:w-auto justify-between md:justify-end border-t md:border-t-0 border-gray-800 pt-6 md:pt-0">
            <div class="text-right flex flex-col items-end">
                <span class="text-[9px] uppercase tracking-[0.3em] text-gray-600 font-black mb-1">MAUT INDEX</span>
                <span class="text-5xl font-black text-red-600 tracking-tighter italic leading-none">${score.toFixed(1)}</span>
            </div>
            <div class="flex md:flex-col gap-2">
                <button onclick="editStudent('${student.id}')" class="p-2 hover:bg-gray-800 rounded-lg text-gray-500 hover:text-white transition-all">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"></path></svg>
                </button>
                <button onclick="deleteStudent('${student.id}')" class="p-2 hover:bg-red-900/20 rounded-lg text-gray-500 hover:text-red-500 transition-all">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                </button>
                <button onclick="exportToPDF('${student.id}')" class="p-2 hover:bg-blue-900/20 rounded-lg text-gray-500 hover:text-blue-400 transition-all">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
                </button>
            </div>
        </div>
    `;

    return div;
}

// Modal Logic
document.getElementById('add-student-btn').onclick = () => {
    editingId = null;
    document.getElementById('modal-title').innerText = 'Register Student';
    studentForm.reset();
    updateMautPreview();
    registrationModal.classList.remove('hidden');
    registrationModal.classList.add('flex');
};

document.getElementById('close-modal').onclick = () => {
    registrationModal.classList.add('hidden');
    registrationModal.classList.remove('flex');
};

function editStudent(id) {
    const s = students.find(x => x.id === id);
    if (!s) return;

    editingId = id;
    document.getElementById('modal-title').innerText = 'Edit Student';
    document.getElementById('student-name').value = s.name;
    document.getElementById('student-belt').value = s.belt;
    document.getElementById('student-technique-name').value = s.mainTech;
    document.getElementById('technique-score').value = s.technique;
    document.getElementById('etiquette-score').value = s.etiquette;
    document.getElementById('attendance-score').value = s.attendance;

    updateMautPreview();
    registrationModal.classList.remove('hidden');
    registrationModal.classList.add('flex');
}

function deleteStudent(id) {
    if (confirm('Delete this student record?')) {
        students = students.filter(x => x.id !== id);
        saveData();
        renderStudents();
    }
}

studentForm.onsubmit = (e) => {
    e.preventDefault();
    const formData = {
        name: document.getElementById('student-name').value,
        belt: document.getElementById('student-belt').value,
        mainTech: document.getElementById('student-technique-name').value,
        technique: parseInt(document.getElementById('technique-score').value),
        etiquette: parseInt(document.getElementById('etiquette-score').value),
        attendance: parseInt(document.getElementById('attendance-score').value),
    };

    if (editingId) {
        const idx = students.findIndex(x => x.id === editingId);
        students[idx] = { ...students[idx], ...formData };
    } else {
        students.unshift({
            id: Date.now().toString(),
            ...formData,
            avatar: null
        });
    }

    saveData();
    renderStudents();
    registrationModal.classList.add('hidden');
    registrationModal.classList.remove('flex');
};

// MAUT Live Preview
function updateMautPreview() {
    const t = parseInt(document.getElementById('technique-score').value);
    const e = parseInt(document.getElementById('etiquette-score').value);
    const a = parseInt(document.getElementById('attendance-score').value);

    document.getElementById('waza-val').innerText = t;
    document.getElementById('reigi-val').innerText = e;
    document.getElementById('attendance-val').innerText = a;

    const score = (t * WEIGHTS.technique) + (e * WEIGHTS.etiquette) + (a * WEIGHTS.attendance);
    document.getElementById('modal-maut-score').innerText = score.toFixed(1);
}

['technique-score', 'etiquette-score', 'attendance-score'].forEach(id => {
    document.getElementById(id).addEventListener('input', updateMautPreview);
});

// Search & Filter
searchInput.addEventListener('input', renderStudents);
beltFilter.addEventListener('change', renderStudents);

// Scanner
function openScanner() {
    document.getElementById('scanner-modal').classList.remove('hidden');
    document.getElementById('scanner-modal').classList.add('flex');
    html5QrCode = new Html5Qrcode("reader");
    html5QrCode.start(
        { facingMode: "environment" },
        { fps: 10, qrbox: { width: 250, height: 250 } },
        (decodedText) => {
            handleAttendance(decodedText);
            stopScanner();
        },
        () => {}
    ).catch(err => {
        console.error(err);
        alert("Camera access failed.");
        stopScanner();
    });
}

function stopScanner() {
    if (html5QrCode) {
        html5QrCode.stop().then(() => {
            document.getElementById('scanner-modal').classList.add('hidden');
            document.getElementById('scanner-modal').classList.remove('flex');
        });
    } else {
        document.getElementById('scanner-modal').classList.add('hidden');
        document.getElementById('scanner-modal').classList.remove('flex');
    }
}

function handleAttendance(id) {
    const student = students.find(s => s.id === id || s.name.toLowerCase() === id.toLowerCase());
    if (student) {
        student.attendance = Math.min(student.attendance + 1, 100);
        saveData();
        renderStudents();
        alert(`Attendance recorded for ${student.name}`);
    } else {
        alert("Student not recognized.");
    }
}

// PDF Exports
async function exportToPDF(id) {
    const { jsPDF } = window.jspdf;
    const s = students.find(x => x.id === id);
    if (!s) return;

    const score = calculateMAUT(s);
    const doc = new jsPDF();

    // Header
    doc.setFillColor(30, 30, 30);
    doc.rect(0, 0, 210, 50, 'F');
    doc.setFillColor(189, 15, 15);
    doc.rect(0, 48, 210, 2, 'F');

    doc.setTextColor(255, 255, 255);
    doc.setFontSize(24);
    doc.setFont("helvetica", "bold");
    doc.text("SHINSEDAIKAN DOJO", 20, 30);
    doc.setFontSize(10);
    doc.setFont("helvetica", "normal");
    doc.text("AIKIDO ASSESSMENT OFFICIAL REPORT", 20, 38);

    // Body
    doc.setTextColor(40, 40, 40);
    doc.setFontSize(22);
    doc.text(s.name.toUpperCase(), 20, 75);

    doc.setFontSize(10);
    doc.setTextColor(100, 100, 100);
    doc.text(`BELT GRADE: ${s.belt.toUpperCase()}`, 20, 83);
    doc.text(`TOKUI WAZA: ${s.mainTech.toUpperCase()}`, 20, 88);

    // Score Box
    doc.setFillColor(250, 250, 250);
    doc.setDrawColor(230, 230, 230);
    doc.roundedRect(140, 65, 50, 40, 3, 3, 'FD');
    doc.setTextColor(189, 15, 15);
    doc.setFontSize(32);
    doc.text(score.toFixed(1), 148, 95);
    doc.setFontSize(8);
    doc.setTextColor(150, 150, 150);
    doc.text("MAUT INDEX SCORE", 148, 75);

    // Breakdown
    doc.setTextColor(30, 30, 30);
    doc.setFontSize(12);
    doc.setFont("helvetica", "bold");
    doc.text("CRITERIA EVALUATION", 20, 115);
    doc.line(20, 118, 190, 118);

    const rows = [
        ["Technique (Waza)", s.technique, "50%", (s.technique * 0.5).toFixed(1)],
        ["Etiquette (Reigi)", s.etiquette, "30%", (s.etiquette * 0.3).toFixed(1)],
        ["Attendance", s.attendance, "20%", (s.attendance * 0.2).toFixed(1)]
    ];

    let y = 130;
    doc.setFontSize(10);
    doc.setTextColor(100, 100, 100);
    doc.text("CRITERION", 20, y);
    doc.text("RAW", 90, y);
    doc.text("WEIGHT", 120, y);
    doc.text("UTILITY", 150, y);

    y += 10;
    doc.setTextColor(40, 40, 40);
    rows.forEach(row => {
        doc.text(row[0], 20, y);
        doc.text(row[1].toString(), 90, y);
        doc.text(row[2], 120, y);
        doc.text(row[3], 150, y);
        y += 10;
    });

    // Footer
    doc.setFontSize(8);
    doc.setTextColor(180, 180, 180);
    doc.text(`Official Document - Generated on ${new Date().toLocaleDateString()}`, 20, 280);
    doc.text("Shinsedaikan Dojo Management System", 140, 280);

    doc.save(`Assessment_${s.name.replace(/\s+/g, '_')}.pdf`);
}

document.getElementById('export-all-btn').onclick = () => {
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF();

    doc.setFillColor(30, 30, 30);
    doc.rect(0, 0, 210, 40, 'F');
    doc.setTextColor(255, 255, 255);
    doc.setFontSize(18);
    doc.text("SHINSEDAIKAN STUDENT ROSTER", 20, 25);

    let y = 55;
    doc.setTextColor(100, 100, 100);
    doc.setFontSize(9);
    doc.text("STUDENT NAME", 20, y);
    doc.text("BELT", 90, y);
    doc.text("MAUT SCORE", 130, y);
    doc.text("MAIN TECHNIQUE", 160, y);

    doc.setDrawColor(200, 200, 200);
    doc.line(20, y + 2, 190, y + 2);

    y += 10;
    doc.setTextColor(40, 40, 40);
    students.forEach(s => {
        const score = calculateMAUT(s);
        doc.text(s.name, 20, y);
        doc.text(s.belt, 90, y);
        doc.text(score.toFixed(1), 130, y);
        doc.text(s.mainTech, 160, y);
        y += 8;
        if (y > 270) {
            doc.addPage();
            y = 20;
        }
    });

    doc.save("Shinsedaikan_Roster.pdf");
};

// Start
renderStudents();
