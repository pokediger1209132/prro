document.addEventListener('DOMContentLoaded', () => {
  const audioPlayer = document.getElementById('audioPlayer');
  const playBtn = document.getElementById('playBtn');
  const pauseBtn = document.getElementById('pauseBtn');
  const volumeCtrl = document.getElementById('volumeCtrl');
  const fileInput = document.getElementById('fileInput');
  const nightcoreToggle = document.getElementById('nightcoreToggle');

  const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  let audioSourceNode = null;

  function updateButtonStates() {
    const noValidSource = !audioPlayer.src || audioPlayer.src === window.location.href || audioPlayer.getAttribute('src') === null || audioPlayer.getAttribute('src') === '';
    
    if (noValidSource) { 
      playBtn.disabled = true;
      pauseBtn.disabled = true;
    } else if (audioPlayer.paused || audioPlayer.ended) { // Added audioPlayer.ended here for robustness
      playBtn.disabled = false;
      pauseBtn.disabled = true;
    } else { // Playing
      playBtn.disabled = true;
      pauseBtn.disabled = false;
    }
  }

  // Initial UI State
  audioPlayer.volume = 0.75;
  volumeCtrl.value = audioPlayer.volume;
  updateButtonStates(); 

  // Play button event listener
  playBtn.addEventListener('click', () => {
    if (audioCtx.state === 'suspended') {
      audioCtx.resume().then(() => {
        console.log("AudioContext resumed successfully");
        if (audioPlayer.getAttribute('src') && audioPlayer.getAttribute('src') !== window.location.href) {
            audioPlayer.play();
        }
      }).catch(e => console.error("Error resuming AudioContext:", e));
    } else {
      if (audioPlayer.getAttribute('src') && audioPlayer.getAttribute('src') !== window.location.href) {
          audioPlayer.play();
      }
    }
  });

  // Pause button event listener
  pauseBtn.addEventListener('click', () => {
    audioPlayer.pause();
  });

  // Volume control event listener
  volumeCtrl.addEventListener('input', () => {
    audioPlayer.volume = volumeCtrl.value;
  });

  // File input event listener
  fileInput.addEventListener('change', (event) => {
    const file = event.target.files[0];

    if (file && file.type.startsWith('audio/')) {
      if (audioPlayer.getAttribute('src') && audioPlayer.getAttribute('src') !== window.location.href && !audioPlayer.paused) {
        audioPlayer.pause(); 
      }
      
      const fileURL = URL.createObjectURL(file);
      // Revoke previous object URL if it exists to free resources
      if (audioPlayer.dataset.previousObjectURL) {
        URL.revokeObjectURL(audioPlayer.dataset.previousObjectURL);
      }
      audioPlayer.dataset.previousObjectURL = fileURL; // Store for future revocation

      audioPlayer.src = fileURL; 
      audioPlayer.currentTime = 0; 

      if (!audioSourceNode) {
        try {
          audioSourceNode = audioCtx.createMediaElementSource(audioPlayer);
          audioSourceNode.connect(audioCtx.destination);
          console.log("Audio source node created and connected.");
        } catch (e) {
          console.error("Error creating media element source:", e);
        }
      }

      if (nightcoreToggle.checked) {
        audioPlayer.playbackRate = 1.5;
      } else {
        audioPlayer.playbackRate = 1.0;
      }
      
      // updateButtonStates will be called by 'loadeddata' or 'canplay', but for immediate feedback:
      playBtn.disabled = false; 
      pauseBtn.disabled = true;  

    } else if (file) { // File selected but not audio
      alert("Please select a valid audio file.");
      // 1. Improve Non-Audio File Handling
      if (!audioPlayer.paused) { // If something was playing, pause it
          audioPlayer.pause();
      }
      audioPlayer.src = ''; // Clear the source
      if (audioPlayer.dataset.previousObjectURL) { // Revoke if one was loaded
        URL.revokeObjectURL(audioPlayer.dataset.previousObjectURL);
        delete audioPlayer.dataset.previousObjectURL;
      }
      fileInput.value = ''; // Reset the file input
      updateButtonStates(); // Update buttons (should disable them)
    } else { // No file selected (e.g., user pressed Cancel in dialog)
       updateButtonStates(); // Reflect current state (might be an existing valid song)
    }
  });

  // Nightcore toggle event listener
  nightcoreToggle.addEventListener('change', () => {
    if (nightcoreToggle.checked) {
      audioPlayer.playbackRate = 1.5;
    } else {
      audioPlayer.playbackRate = 1.0;
    }
  });

  // Event listeners for audio state changes
  audioPlayer.addEventListener('play', updateButtonStates);
  audioPlayer.addEventListener('pause', updateButtonStates);
  
  audioPlayer.addEventListener('ended', () => {
    // 2. Ensure Audio Resets on End
    audioPlayer.currentTime = 0; 
    updateButtonStates();
  });

  audioPlayer.addEventListener('emptied', () => {
    // When src is set to '', this event fires.
    // We want buttons to be disabled.
    updateButtonStates();
  }); 

  audioPlayer.addEventListener('loadeddata', () => {
    updateButtonStates(); 
    if (!audioSourceNode && audioPlayer.src && audioPlayer.src !== window.location.href && audioPlayer.src.startsWith('blob:')) {
        try {
            // Re-check and create source node if it wasn't created or got disconnected.
            // This check for audioSourceNode might be redundant if we ensure it's always created after src set.
            // However, ensuring it's connected is important.
            if (audioSourceNode && audioSourceNode.mediaElement !== audioPlayer) {
                audioSourceNode.disconnect();
                audioSourceNode = null; // Force recreation with the new element
            }
            if(!audioSourceNode) {
                audioSourceNode = audioCtx.createMediaElementSource(audioPlayer);
            }
            // Ensure it's connected (it might have been disconnected or never connected)
            // To avoid multiple connections, we can try disconnecting first, though it's often safe.
            // audioSourceNode.disconnect(audioCtx.destination); // Optional: disconnect if unsure
            audioSourceNode.connect(audioCtx.destination);
            console.log("Audio source node (re-)created and connected on loadeddata.");
        } catch (e) {
            console.error("Error creating media element source on loadeddata:", e);
        }
    } else if (audioSourceNode && audioPlayer.src && audioPlayer.src.startsWith('blob:') && audioSourceNode.mediaElement !== audioPlayer) {
        // This case might occur if audioPlayer was reused but source node points to an old instance.
        // This is less likely with current HTML setup where audioPlayer is static.
        console.warn("Audio source node points to a different media element. Recreating.");
        audioSourceNode.disconnect();
        audioSourceNode = audioCtx.createMediaElementSource(audioPlayer);
        audioSourceNode.connect(audioCtx.destination);
    }
  });
  audioPlayer.addEventListener('error', () => {
    alert("Error playing audio file.");
    audioPlayer.src = ''; // Clear the problematic source
    if (audioPlayer.dataset.previousObjectURL) {
        URL.revokeObjectURL(audioPlayer.dataset.previousObjectURL);
        delete audioPlayer.dataset.previousObjectURL;
    }
    fileInput.value = '';
    updateButtonStates(); 
  });

  audioPlayer.addEventListener('volumechange', () => {
    volumeCtrl.value = audioPlayer.volume;
  });
});
