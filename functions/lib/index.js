const admin = require('firebase-admin');

admin.initializeApp();

// Password reset and account verification now use Firebase Auth email links
// directly from the client app. PIN/code-based verification endpoints were
// intentionally removed.