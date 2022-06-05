var noSleep = new NoSleep();
var noWakeEnabled = false;
var noWakeElement = document.querySelector("#nowake");

noWakeElement.addEventListener('click', function() {
  if (!noWakeEnabled) {
    noSleep.enable();
    noWakeEnabled = true;
    noWakeElement.textContent = "Screen Awake! Click to disable";
    noWakeElement.style.backgroundColor = "#3f9cff";
    noWakeElement.style.color = "#FFFFFF"
  } else {
    noSleep.disable();
    noWakeEnabled = false;
    noWakeElement.textContent = "Click to prevent screen from sleeping";
    noWakeElement.style.backgroundColor = "white";
    noWakeElement.style.color = "#000000"
  }
}, false);