let playerData = {};
let config = {};
let dashboardData = {};

// =====================================================
// EVENT LISTENERS
// =====================================================

window.addEventListener('message', function(event) {
    const data = event.data;
    console.log('[UN-Government NUI] Received message:', data);
    
    switch(data.action) {
        case 'openDashboard':
            console.log('[UN-Government NUI] Opening dashboard');
            openDashboard(data);
            break;
        case 'openVotingKiosk':
            console.log('[UN-Government NUI] Opening voting kiosk');
            openVotingKiosk(data);
            break;
    }
});

document.addEventListener('DOMContentLoaded', function() {
    console.log('[UN-Government NUI] DOM loaded, setting up navigation');
    setupNavigation();
    setupPermissionFiltering();
});

// =====================================================
// DASHBOARD FUNCTIONS
// =====================================================

function openDashboard(data) {
    console.log('[UN-Government NUI] openDashboard called with data:', data);
    
    playerData = data.playerData;
    config = data.config;
    dashboardData = data.data;
    
    console.log('[UN-Government NUI] Player data:', playerData);
    console.log('[UN-Government NUI] Config:', config);
    console.log('[UN-Government NUI] Dashboard data:', dashboardData);
    
    // Update header
    document.getElementById('user-name').textContent = playerData.name;
    document.getElementById('user-job').textContent = playerData.jobLabel;
    
    // Update stats
    document.getElementById('stat-active-votes').textContent = dashboardData.activeVotes;
    document.getElementById('stat-pending-appointments').textContent = dashboardData.pendingAppointments;
    document.getElementById('stat-balance').textContent = formatCurrency(dashboardData.governmentBalance);
    
    // Filter navigation based on permissions
    filterNavigation();
    
    console.log('[UN-Government NUI] Showing dashboard');
    // Show dashboard
    document.getElementById('government-dashboard').style.display = 'flex';
    
    // Load default section
    loadSection('overview');
}

function closeDashboard() {
    document.getElementById('government-dashboard').style.display = 'none';
    fetch('https://un-government/closeDashboard', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    });
}

// =====================================================
// NAVIGATION
// =====================================================

function setupNavigation() {
    const tabs = document.querySelectorAll('.tab');
    tabs.forEach(tab => {
        tab.addEventListener('click', function() {
            const tabName = this.getAttribute('data-tab');
            switchTab(tabName);
        });
    });
    
    // Setup vote filter buttons
    const filterBtns = document.querySelectorAll('.filter-btn');
    filterBtns.forEach(btn => {
        btn.addEventListener('click', function() {
            filterBtns.forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            loadVotes(this.getAttribute('data-filter'));
        });
    });
}

function switchTab(tabName) {
    console.log('[UN-Government NUI] Switching to tab:', tabName);
    
    // Update tabs
    document.querySelectorAll('.tab').forEach(tab => {
        tab.classList.remove('active');
    });
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
    
    // Update content sections
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    document.getElementById(tabName).classList.add('active');
    
    // Load section data
    loadSection(tabName);
}

function loadSection(section) {
    switch(section) {
        case 'voting':
            loadVotes('active');
            break;
        case 'appointments':
            loadAppointments();
            break;
        case 'budget':
            loadBudget();
            break;
        case 'inspections':
            // Inspection history loaded on search
            break;
        case 'officials':
            loadOfficials();
            break;
    }
}

function filterNavigation() {
    const tabs = document.querySelectorAll('.tab[data-permission]');
    tabs.forEach(tab => {
        const permission = tab.getAttribute('data-permission');
        if (!hasPermission(permission)) {
            tab.style.display = 'none';
        }
    });
}

function setupPermissionFiltering() {
    // Hide buttons that require permissions
    document.querySelectorAll('[data-permission]').forEach(element => {
        const permission = element.getAttribute('data-permission');
        if (!hasPermission(permission)) {
            element.style.display = 'none';
        }
    });
}

function hasPermission(permission) {
    if (playerData.isGod) return true;
    if (!dashboardData.permissions) return false;
    return dashboardData.permissions.includes(permission);
}

// =====================================================
// VOTING SYSTEM
// =====================================================

function loadVotes(filter = 'active') {
    fetch('https://un-government/getVotes', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ filter: filter })
    })
    .then(response => response.json())
    .then(votes => {
        displayVotes(votes);
    });
}

function displayVotes(votes) {
    const votesList = document.getElementById('votes-list');
    votesList.innerHTML = '';
    
    if (votes.length === 0) {
        votesList.innerHTML = '<p class="no-data">No votes found</p>';
        return;
    }
    
    votes.forEach(vote => {
        const voteCard = createVoteCard(vote);
        votesList.appendChild(voteCard);
    });
}

function createVoteCard(vote) {
    const card = document.createElement('div');
    card.className = 'vote-card';
    
    const totalVotes = Object.values(vote.results || {}).reduce((a, b) => a + b, 0);
    
    let optionsHTML = '';
    if (vote.status === 'active' && !vote.hasVoted) {
        vote.options.forEach(option => {
            optionsHTML += `<button class="vote-option" onclick="castVote(${vote.id}, '${option}')">${option}</button>`;
        });
    } else {
        // Show results
        optionsHTML = '<div class="vote-results">';
        vote.options.forEach(option => {
            const count = vote.results[option] || 0;
            const percentage = totalVotes > 0 ? (count / totalVotes * 100).toFixed(1) : 0;
            optionsHTML += `
                <div class="result-bar">
                    <div class="result-label">
                        <span>${option}</span>
                        <span>${count} votes (${percentage}%)</span>
                    </div>
                    <div class="progress-bar">
                        <div class="progress-fill" style="width: ${percentage}%"></div>
                    </div>
                </div>
            `;
        });
        optionsHTML += '</div>';
    }
    
    card.innerHTML = `
        <div class="vote-header">
            <h3 class="vote-title">${vote.title}</h3>
            <span class="vote-type">${vote.type}</span>
        </div>
        <p class="vote-description">${vote.description}</p>
        <div class="vote-info">
            <span><i class="fas fa-user"></i> ${vote.created_by_name}</span>
            <span><i class="fas fa-briefcase"></i> ${vote.created_by_job}</span>
            <span><i class="fas fa-clock"></i> ${formatDate(vote.created_date)}</span>
            ${vote.status === 'active' ? `<span><i class="fas fa-hourglass-half"></i> Ends: ${formatDate(vote.end_time)}</span>` : ''}
        </div>
        <div class="vote-options">
            ${optionsHTML}
        </div>
        ${vote.status === 'ended' ? `<p style="margin-top: 15px; color: ${vote.passed ? 'var(--success-color)' : 'var(--error-color)'}; font-weight: 600;"><i class="fas fa-${vote.passed ? 'check-circle' : 'times-circle'}"></i> ${vote.passed ? 'PASSED' : 'FAILED'}</p>` : ''}
    `;
    
    return card;
}

function showCreateVoteModal() {
    document.getElementById('create-vote-modal').style.display = 'flex';
}

function createVote() {
    const type = document.getElementById('vote-type').value;
    const title = document.getElementById('vote-title').value;
    const description = document.getElementById('vote-description').value;
    const duration = parseInt(document.getElementById('vote-duration').value);
    const optionsText = document.getElementById('vote-options').value;
    const options = optionsText.split('\n').filter(o => o.trim() !== '');
    
    if (!title || !description || options.length === 0) {
        alert('Please fill in all required fields');
        return;
    }
    
    fetch('https://un-government/createVote', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
            type: type,
            title: title,
            description: description,
            duration: duration,
            options: options
        })
    })
    .then(response => response.json())
    .then(result => {
        if (result.success) {
            closeModal('create-vote-modal');
            loadVotes('active');
        } else {
            alert(result.message);
        }
    });
}

function castVote(voteId, option) {
    fetch('https://un-government/castVote', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
            voteId: voteId,
            option: option
        })
    })
    .then(response => response.json())
    .then(result => {
        if (result.success) {
            loadVotes('active');
        } else {
            alert(result.message);
        }
    });
}

// Vote filter buttons
document.addEventListener('DOMContentLoaded', function() {
    const filterBtns = document.querySelectorAll('.filter-btn');
    filterBtns.forEach(btn => {
        btn.addEventListener('click', function() {
            filterBtns.forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            loadVotes(this.getAttribute('data-filter'));
        });
    });
});

// =====================================================
// APPOINTMENTS SYSTEM
// =====================================================

function loadAppointments() {
    fetch('https://un-government/getAppointments', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(appointments => {
        displayAppointments(appointments);
    });
}

function displayAppointments(appointments) {
    const list = document.getElementById('appointments-list');
    list.innerHTML = '';
    
    if (appointments.length === 0) {
        list.innerHTML = '<p class="no-data">No appointments found</p>';
        return;
    }
    
    appointments.forEach(appointment => {
        const card = document.createElement('div');
        card.className = 'appointment-card';
        
        const statusColor = appointment.status === 'approved' ? 'var(--success-color)' : 
                          appointment.status === 'pending' ? 'var(--warning-color)' : 
                          'var(--error-color)';
        
        card.innerHTML = `
            <div style="display: flex; justify-content: space-between; align-items: start;">
                <div>
                    <h3 style="color: var(--text-primary); margin-bottom: 8px;">${appointment.name}</h3>
                    <p style="color: var(--accent-color); font-size: 18px; margin-bottom: 8px;">${appointment.job_label}</p>
                    <p style="color: var(--text-secondary); font-size: 14px;">Appointed by: ${appointment.appointed_by_name}</p>
                    <p style="color: var(--text-secondary); font-size: 14px;">${formatDate(appointment.created_date)}</p>
                </div>
                <div style="text-align: right;">
                    <span style="background: ${statusColor}; color: white; padding: 5px 15px; border-radius: 20px; font-size: 12px; font-weight: 600; text-transform: uppercase;">${appointment.status}</span>
                </div>
            </div>
        `;
        
        list.appendChild(card);
    });
}

function showAppointModal() {
    // Populate job dropdown based on permissions
    const jobSelect = document.getElementById('appoint-job');
    jobSelect.innerHTML = '';
    
    // This would be populated based on Config.Appointments.canAppoint
    // For now, showing all government jobs
    Object.keys(config.GovernmentJobs || {}).forEach(job => {
        const option = document.createElement('option');
        option.value = job;
        option.textContent = config.GovernmentJobs[job].label;
        jobSelect.appendChild(option);
    });
    
    document.getElementById('appoint-modal').style.display = 'flex';
}

function appointOfficial() {
    const citizenid = document.getElementById('appoint-citizenid').value;
    const job = document.getElementById('appoint-job').value;
    const notes = document.getElementById('appoint-notes').value;
    
    if (!citizenid || !job) {
        alert('Please fill in required fields');
        return;
    }
    
    fetch('https://un-government/appointOfficial', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
            citizenid: citizenid,
            job: job,
            notes: notes
        })
    })
    .then(response => response.json())
    .then(result => {
        if (result.success) {
            closeModal('appoint-modal');
            loadAppointments();
        } else {
            alert(result.message);
        }
    });
}

// =====================================================
// BUDGET MANAGEMENT
// =====================================================

function loadBudget() {
    fetch('https://un-government/getBudgetData', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(budgetData => {
        displayBudget(budgetData);
    });
}

function displayBudget(budgetData) {
    const overview = document.getElementById('budget-overview');
    overview.innerHTML = '';
    
    if (!budgetData || !budgetData.departments) {
        overview.innerHTML = '<p class="no-data">No budget data available</p>';
        return;
    }
    
    Object.entries(budgetData.departments).forEach(([dept, data]) => {
        const card = document.createElement('div');
        card.className = 'department-budget';
        card.innerHTML = `
            <h3 class="department-name">${data.label}</h3>
            <p class="budget-amount">${formatCurrency(data.balance)}</p>
            <p class="budget-allocation">Monthly: ${formatCurrency(data.monthlyAllocation)}</p>
        `;
        overview.appendChild(card);
    });
    
    // Display transactions
    const transactionsList = document.getElementById('transactions-list');
    transactionsList.innerHTML = '';
    
    if (budgetData.transactions && budgetData.transactions.length > 0) {
        budgetData.transactions.forEach(tx => {
            const item = document.createElement('div');
            item.style.cssText = 'padding: 15px; border-bottom: 1px solid var(--border-color);';
            item.innerHTML = `
                <div style="display: flex; justify-content: space-between; align-items: center;">
                    <div>
                        <p style="color: var(--text-primary); font-weight: 600; margin-bottom: 5px;">${tx.description}</p>
                        <p style="color: var(--text-secondary); font-size: 14px;">${formatDate(tx.transaction_date)}</p>
                    </div>
                    <p style="color: ${tx.amount > 0 ? 'var(--success-color)' : 'var(--error-color)'}; font-size: 18px; font-weight: 700;">${tx.amount > 0 ? '+' : ''}${formatCurrency(tx.amount)}</p>
                </div>
            `;
            transactionsList.appendChild(item);
        });
    } else {
        transactionsList.innerHTML = '<p class="no-data">No transactions found</p>';
    }
}

// =====================================================
// INSPECTION SYSTEM
// =====================================================

function searchInspections() {
    const businessName = document.getElementById('business-search').value;
    
    fetch('https://un-government/getInspectionHistory', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ businessName: businessName })
    })
    .then(response => response.json())
    .then(history => {
        displayInspections(history);
    });
}

function displayInspections(inspections) {
    const list = document.getElementById('inspections-list');
    list.innerHTML = '';
    
    if (inspections.length === 0) {
        list.innerHTML = '<p class="no-data">No inspection history found</p>';
        return;
    }
    
    inspections.forEach(inspection => {
        const card = document.createElement('div');
        card.className = 'inspection-card';
        card.innerHTML = `
            <h3 style="color: var(--text-primary); margin-bottom: 10px;">${inspection.business_name}</h3>
            <p style="color: var(--accent-color); font-size: 18px; margin-bottom: 10px;">Grade: ${inspection.grade || 'N/A'}</p>
            <p style="color: var(--text-secondary);">Inspector: ${inspection.inspector_name}</p>
            <p style="color: var(--text-secondary);">Date: ${formatDate(inspection.inspection_date)}</p>
        `;
        list.appendChild(card);
    });
}

function startInspection() {
    fetch('https://un-government/startInspection', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    });
    closeDashboard();
}

// =====================================================
// OFFICIALS DIRECTORY
// =====================================================

function loadOfficials() {
    fetch('https://un-government/getGovernmentOfficials', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(officials => {
        displayOfficials(officials);
    });
}

function displayOfficials(officials) {
    const list = document.getElementById('officials-list');
    list.innerHTML = '';
    
    if (officials.length === 0) {
        list.innerHTML = '<p class="no-data">No government officials currently online</p>';
        return;
    }
    
    officials.forEach(official => {
        const card = document.createElement('div');
        card.className = 'official-card';
        card.innerHTML = `
            <div class="official-info">
                <h3 class="official-name">${official.name}</h3>
                <p class="official-job">${official.jobLabel}</p>
                <p class="official-contact"><i class="fas fa-phone"></i> ${official.phone}</p>
            </div>
        `;
        list.appendChild(card);
    });
}

// =====================================================
// VOTING KIOSK (PUBLIC)
// =====================================================

function openVotingKiosk(data) {
    const votesList = document.getElementById('public-votes-list');
    votesList.innerHTML = '';
    
    if (data.votes.length === 0) {
        votesList.innerHTML = '<p class="no-data">No active votes at this time</p>';
    } else {
        data.votes.forEach(vote => {
            const voteCard = createVoteCard(vote);
            votesList.appendChild(voteCard);
        });
    }
    
    document.getElementById('voting-kiosk').style.display = 'flex';
}

function closeVotingKiosk() {
    document.getElementById('voting-kiosk').style.display = 'none';
    fetch('https://un-government/closeVotingKiosk', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({})
    });
}

// =====================================================
// LEGISLATION SYSTEM
// =====================================================

// Setup law filter buttons
document.addEventListener('DOMContentLoaded', function() {
    const lawFilterBtns = document.querySelectorAll('.law-filter-btn');
    lawFilterBtns.forEach(btn => {
        btn.addEventListener('click', function() {
            lawFilterBtns.forEach(b => b.classList.remove('active'));
            this.classList.add('active');
            loadLaws(this.getAttribute('data-filter'));
        });
    });
});

let currentLawId = null;

function loadLaws(filter = 'active') {
    fetch('https://un-government/getLaws', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ filter: filter })
    })
    .then(response => response.json())
    .then(laws => {
        displayLaws(laws, filter);
    });
}

function displayLaws(laws, filter) {
    const lawsList = document.getElementById('laws-list');
    lawsList.innerHTML = '';
    
    if (laws.length === 0) {
        lawsList.innerHTML = '<p class="no-data">No laws found</p>';
        return;
    }
    
    laws.forEach(law => {
        const lawCard = createLawCard(law, filter);
        lawsList.appendChild(lawCard);
    });
}

function createLawCard(law, filter) {
    const card = document.createElement('div');
    card.className = 'law-card';
    
    if (filter === 'vetoed') {
        card.classList.add('law-card-vetoed');
    } else if (filter === 'active') {
        card.classList.add('law-card-active');
    } else if (filter === 'proposed') {
        card.classList.add('law-card-proposed');
    }
    
    const totalVotes = Object.values(law.results || {}).reduce((a, b) => a + b, 0);
    const yesVotes = law.results?.yes || law.results?.Yes || 0;
    const yesPercentage = totalVotes > 0 ? (yesVotes / totalVotes * 100).toFixed(1) : 0;
    
    let statusBadge = '';
    if (filter === 'active') {
        statusBadge = '<span class="law-status-badge law-status-active">ACTIVE LAW</span>';
    } else if (filter === 'proposed') {
        statusBadge = '<span class="law-status-badge law-status-proposed">IN VOTING</span>';
    } else if (filter === 'vetoed') {
        statusBadge = '<span class="law-status-badge law-status-vetoed">VETO\'D</span>';
    }
    
    card.innerHTML = `
        <div class="law-header">
            <div>
                <h3 class="law-title">${law.title}</h3>
                ${statusBadge}
            </div>
            <button class="btn-view-law" onclick="viewLawDetails(${law.id})">
                <i class="fas fa-eye"></i> View Details
            </button>
        </div>
        <p class="law-description">${law.description.substring(0, 150)}${law.description.length > 150 ? '...' : ''}</p>
        <div class="law-info">
            <span><i class="fas fa-user"></i> ${law.created_by_name}</span>
            <span><i class="fas fa-calendar"></i> ${formatDate(law.created_date)}</span>
            ${filter === 'proposed' ? `<span><i class="fas fa-clock"></i> Ends: ${formatDate(law.end_time)}</span>` : ''}
            ${filter === 'active' ? `<span><i class="fas fa-check-circle"></i> Passed: ${formatDate(law.passed_date)}</span>` : ''}
        </div>
        ${filter !== 'active' && totalVotes > 0 ? `
            <div class="law-vote-summary">
                <div class="vote-summary-bar">
                    <div class="vote-summary-yes" style="width: ${yesPercentage}%"></div>
                </div>
                <div class="vote-summary-text">
                    <span style="color: var(--success-color);">Yes: ${yesVotes} (${yesPercentage}%)</span>
                    <span style="color: var(--error-color);">No: ${(totalVotes - yesVotes)} (${(100 - yesPercentage).toFixed(1)}%)</span>
                </div>
            </div>
        ` : ''}
    `;
    
    return card;
}

function showProposeLawModal() {
    document.getElementById('propose-law-modal').style.display = 'flex';
}

function proposeLaw() {
    const title = document.getElementById('law-title').value.trim();
    const description = document.getElementById('law-description').value.trim();
    const duration = parseInt(document.getElementById('law-vote-duration').value);
    
    if (!title || !description) {
        alert('Please fill in all required fields');
        return;
    }
    
    if (duration < 24 || duration > 168) {
        alert('Vote duration must be between 24 and 168 hours');
        return;
    }
    
    fetch('https://un-government/proposeLaw', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
            title: title,
            description: description,
            duration: duration
        })
    })
    .then(response => response.json())
    .then(result => {
        if (result.success) {
            closeModal('propose-law-modal');
            loadLaws('proposed');
        } else {
            alert(result.message || 'Failed to propose law');
        }
    });
}

function viewLawDetails(lawId) {
    currentLawId = lawId;
    
    fetch('https://un-government/getLawDetails', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ lawId: lawId })
    })
    .then(response => response.json())
    .then(law => {
        displayLawDetails(law);
    });
}

function displayLawDetails(law) {
    document.getElementById('law-modal-title').textContent = law.title;
    document.getElementById('law-modal-status').textContent = law.status.toUpperCase();
    document.getElementById('law-modal-proposer').textContent = law.created_by_name + ' (' + law.created_by_job + ')';
    document.getElementById('law-modal-created').textContent = formatDate(law.created_date);
    document.getElementById('law-modal-end-time').textContent = law.status === 'proposed' ? formatDate(law.end_time) : 'N/A';
    document.getElementById('law-modal-description').textContent = law.description;
    
    // Display vote results
    const resultsDiv = document.getElementById('law-vote-results');
    resultsDiv.innerHTML = '';
    
    const totalVotes = Object.values(law.results || {}).reduce((a, b) => a + b, 0);
    
    if (totalVotes > 0) {
        const yesVotes = law.results?.yes || law.results?.Yes || 0;
        const noVotes = law.results?.no || law.results?.No || 0;
        const yesPercentage = totalVotes > 0 ? (yesVotes / totalVotes * 100).toFixed(1) : 0;
        const noPercentage = totalVotes > 0 ? (noVotes / totalVotes * 100).toFixed(1) : 0;
        
        resultsDiv.innerHTML = `
            <div class="vote-result-item">
                <div class="vote-result-label">
                    <i class="fas fa-check-circle" style="color: var(--success-color);"></i>
                    <span>Yes Votes</span>
                </div>
                <div class="vote-result-bar">
                    <div class="vote-result-fill success" style="width: ${yesPercentage}%"></div>
                </div>
                <div class="vote-result-count">${yesVotes} votes (${yesPercentage}%)</div>
            </div>
            <div class="vote-result-item">
                <div class="vote-result-label">
                    <i class="fas fa-times-circle" style="color: var(--error-color);"></i>
                    <span>No Votes</span>
                </div>
                <div class="vote-result-bar">
                    <div class="vote-result-fill error" style="width: ${noPercentage}%"></div>
                </div>
                <div class="vote-result-count">${noVotes} votes (${noPercentage}%)</div>
            </div>
        `;
    } else {
        resultsDiv.innerHTML = '<p class="no-data">No votes cast yet</p>';
    }
    
    // Show/hide action buttons based on status and permissions
    const yesBtn = document.getElementById('law-vote-yes-btn');
    const noBtn = document.getElementById('law-vote-no-btn');
    const vetoBtn = document.getElementById('law-veto-btn');
    
    yesBtn.style.display = 'none';
    noBtn.style.display = 'none';
    vetoBtn.style.display = 'none';
    
    if (law.status === 'proposed' && !law.hasVoted) {
        yesBtn.style.display = 'inline-block';
        noBtn.style.display = 'inline-block';
    }
    
    if (law.status === 'proposed' && hasPermission('veto_laws')) {
        vetoBtn.style.display = 'inline-block';
    }
    
    document.getElementById('view-law-modal').style.display = 'flex';
}

function voteOnLaw(vote) {
    if (!currentLawId) return;
    
    fetch('https://un-government/voteOnLaw', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
            lawId: currentLawId,
            vote: vote
        })
    })
    .then(response => response.json())
    .then(result => {
        if (result.success) {
            closeModal('view-law-modal');
            loadLaws('proposed');
        } else {
            alert(result.message || 'Failed to cast vote');
        }
    });
}

function vetoLaw() {
    if (!currentLawId) return;
    
    if (!confirm('Are you sure you want to veto this law? This action cannot be undone.')) {
        return;
    }
    
    fetch('https://un-government/vetoLaw', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({
            lawId: currentLawId
        })
    })
    .then(response => response.json())
    .then(result => {
        if (result.success) {
            closeModal('view-law-modal');
            loadLaws('vetoed');
        } else {
            alert(result.message || 'Failed to veto law');
        }
    });
}

// =====================================================
// MODAL FUNCTIONS
// =====================================================

function closeModal(modalId) {
    document.getElementById(modalId).style.display = 'none';
    
    // Clear form fields
    document.querySelectorAll(`#${modalId} input, #${modalId} textarea, #${modalId} select`).forEach(field => {
        field.value = '';
    });
}

// =====================================================
// UTILITY FUNCTIONS
// =====================================================

function formatCurrency(amount) {
    return '$' + amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function formatDate(dateString) {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
}

// Close modal when clicking outside
window.onclick = function(event) {
    if (event.target.classList.contains('modal')) {
        event.target.style.display = 'none';
    }
}

// ESC key to close
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        const dashboard = document.getElementById('government-dashboard');
        const kiosk = document.getElementById('voting-kiosk');
        
        if (dashboard.style.display !== 'none') {
            closeDashboard();
        } else if (kiosk.style.display !== 'none') {
            closeVotingKiosk();
        }
        
        // Close any open modals
        document.querySelectorAll('.modal').forEach(modal => {
            modal.style.display = 'none';
        });
    }
});
