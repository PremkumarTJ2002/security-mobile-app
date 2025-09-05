importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker by passing in the messagingSenderId
firebase.initializeApp({
  apiKey: "AIzaSyD1dv22B_Hk98Quyv0l2mRz3Bb29-bGVHg",
  authDomain: "visitor-entry-app-1a330.firebaseapp.com",
  projectId: "visitor-entry-app-1a330",
  storageBucket: "visitor-entry-app-1a330.firebasestorage.app",
  messagingSenderId: "454921925709",
  appId: "1:454921925709:web:31ebe6b92ac29703579804"
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();
