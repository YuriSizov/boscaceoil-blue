const BOSCAWEB_STATE_INITIAL  = 0;
const BOSCAWEB_STATE_PROGRESS = 1;
const BOSCAWEB_STATE_READY    = 2;
const BOSCAWEB_STATE_FAILED   = 3;

class BoscaWeb {
	constructor() {
		this.initializing = true;
		this.engine = new Engine(GODOT_CONFIG);
		
		this._bootOverlay = document.getElementById('boot-overlay');
		this._boot_initialState = document.getElementById('boot-menu');
		this._boot_progressState = document.getElementById('boot-progress');
		this._boot_failedState = document.getElementById('boot-fatal-error');
		
		this._bootButton = document.getElementById('boot-init-button');
		this._bootButton.addEventListener('click', () => {
			this.init();
		});
		
		this._progressBar = document.getElementById('boot-progress-bar');
		this._progressStatus = document.getElementById('boot-progress-status');
		
		this._progressValues = {};
		for (const filename in BOSCA_FILE_SIZES) {
			this._progressValues[filename] = { 'total': BOSCA_FILE_SIZES[filename], 'loaded': 0 };
		}
		
		this._compat_passedState = document.getElementById('boot-compat-passed');
		this._compat_failedState = document.getElementById('boot-compat-failed');
		this._compat_failedList = document.getElementById('boot-compat-list');
		this._compat_tryfixButton = document.getElementById('boot-compat-tryfix');
		this._compat_tryfixButton.addEventListener('click', () => {
			this.tryFixCompatibility();
		});
		
		this._compatible = false;
		this._compatFixable = (GODOT_CONFIG['serviceWorker'] && GODOT_CONFIG['ensureCrossOriginIsolationHeaders'] && 'serviceWorker' in navigator);
		
		// Hidden by default to show native error messages, e.g. if JavaScript
		// is disabled in the browser.
		this._bootOverlay.style.visibility = 'visible';
		this.setState(BOSCAWEB_STATE_INITIAL);
	}
	
	checkCompatibility() {
		this._bootButton.classList.remove('boot-init-suppressed');
		this._compat_passedState.style.display = 'none';
		this._compat_failedState.style.display = 'none';
		this._compat_tryfixButton.style.display = 'none';
		this._compat_failedList.style.display = 'none';
		this._setErrorText(this._compat_failedList, '');
		
		const missingFeatures = Engine.getMissingFeatures({
			threads: GODOT_THREADS_ENABLED,
		});
		
		if (missingFeatures.length > 0) {
			this._compatible = false;
			this._bootButton.classList.add('boot-init-suppressed');
			this._compat_failedState.style.display = 'flex';
			this._compat_failedList.style.display = 'block';
			this._compat_tryfixButton.style.display = (this._compatFixable ? 'inline-block' : 'none');
			
			const sectionHeader = document.createElement('strong');
			sectionHeader.textContent = 'Your browser is missing following features: ';
			this._compat_failedList.appendChild(sectionHeader);
			
			const sectionList = document.createElement('span');
			this._compat_failedList.appendChild(sectionList);
			missingFeatures.forEach((item, index) => {
				const itemParts = item.split(' - ');
				
				const annotatedElement = document.createElement('abbr');
				annotatedElement.textContent = itemParts[0];
				annotatedElement.title = itemParts[1];
				sectionList.appendChild(annotatedElement);
				
				if (index < missingFeatures.length - 1) {
					sectionList.appendChild(document.createTextNode(", "));
				}
			});
		} else {
			this._compatible = true;
			this._compat_passedState.style.display = 'flex';
		}
	}
	
	async tryFixCompatibility() {
		if (!this._compatFixable) {
			return;
		}
		
		// There's a chance that installing the service worker will fix the issue.
		// Taken from Godot sources, see full-size.html for the up-to-date version.
		
		try {
			await Promise.race([
				navigator.serviceWorker.getRegistration()
					.then((registration) => {
						if (registration != null) {
							return Promise.reject(new Error('Service worker already exists.'));
						}
						return registration;
					})
					.then(() => this.engine.installServiceWorker()),
				
				// For some reason, `getRegistration()` can stall.
				new Promise((resolve) => {
					setTimeout(() => resolve(), 2000);
				}),
			]);
		} catch (err) {
			console.error('Error while registering service worker:', err);
		}
		
		// FIXME: This can potentially reload-loop indefinitely, which isn't great.
		window.location.reload();
	}
	
	async init() {
		this._updateBootProgress();
		this.setState(BOSCAWEB_STATE_PROGRESS);
		
		try {
			await this.engine.startGame();
			this.setState(BOSCAWEB_STATE_READY);
		} catch (err) {
			this._fatalError(err);
		}
	}
	
	setState(mode) {
		if (this.state === mode || !this.initializing) {
			return;
		}
		this.state = mode;
		
		if (this.state === BOSCAWEB_STATE_READY) {
			this._bootOverlay.remove();
			this.initializing = false;
			return;
		}
		
		this._boot_initialState.style.display  = (this.state === BOSCAWEB_STATE_INITIAL  ? 'flex'  : 'none');
		this._boot_progressState.style.display = (this.state === BOSCAWEB_STATE_PROGRESS ? 'flex' : 'none');
		this._boot_failedState.style.display   = (this.state === BOSCAWEB_STATE_FAILED   ? 'block' : 'none');
	}
	
	setLoadingProgress(file, chunkSize) {
		this._progressValues[file].loaded += chunkSize;
		requestAnimationFrame(this._updateBootProgress.bind(this));
	}
	
	_updateBootProgress() {
		let total = Object.values(this._progressValues).reduce((sum, val) => sum + val.total, 0);
		let loaded = Object.values(this._progressValues).reduce((sum, val) => sum + val.loaded, 0);
		
		if (loaded > 0 && total > 0) {
			this._progressBar.value = loaded;
			this._progressBar.max = total;
			
			if (loaded >= total) {
				this._progressStatus.textContent = "Launching, it may take a moment...";
			}
		} else {
			this._progressBar.removeAttribute('value');
			this._progressBar.removeAttribute('max');
		}
	}
	
	_setErrorText(element, text) {
		while (element.lastChild) {
			element.removeChild(element.lastChild);
		}
		
		if (text === '') {
			return;
		}
		
		const lines = text.split('\n');
		lines.forEach((line) => {
			element.appendChild(document.createTextNode(line));
			element.appendChild(document.createElement('br'));
		});
	}
	
	_fatalError(err) {
		console.error(err);
		
		if (err instanceof Error) {
			this._setErrorText(this._boot_failedState, err.message);
		} else if (typeof err === 'string') {
			this._setErrorText(this._boot_failedState, err);
		} else {
			this._setErrorText(this._boot_failedState, 'An unknown error occurred.');
		}
		
		this.setState(BOSCAWEB_STATE_FAILED);
		this.initializing = false;
	}
}
