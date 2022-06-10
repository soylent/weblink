var noSleep = new NoSleep();
var noSleepCheckbox = document.getElementById("nosleep");

document.addEventListener("visibilitychange", function resetNoSleep(event) {
  if (document.visibilityState === "visible") {
    noSleep.disable();
    noSleep = new NoSleep();
    noSleepCheckbox.checked = false;
  }
});

noSleepCheckbox.addEventListener("click", function toggleNoSleep(event) {
  if (noSleep.isEnabled) {
    noSleep.disable();
  } else {
    try {
      noSleep.enable();
    } catch (error) {
      event.preventDefault();
    }
  }
});