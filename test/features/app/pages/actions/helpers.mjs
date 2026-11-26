const helpers = {
  awaitRelease() {
    return new Promise((resolve) => {
      window.releaseLateAction = resolve;
    });
  },

  neverSettle() {
    return new Promise(() => {});
  },

  slowValue(ms) {
    return new Promise((resolve) => {
      setTimeout(() => resolve(ms), ms);
    });
  },
};

export default helpers;
