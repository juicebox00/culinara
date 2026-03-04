const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Initialize Firebase Admin
admin.initializeApp();

// Configure email service (using Gmail or your email provider)
// For production, use environment variables
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD,
  },
});

// Store verification codes in Firestore with expiration
const db = admin.firestore();
const VERIFICATION_CODE_EXPIRATION = 10 * 60 * 1000; // 10 minutes

/**
 * Generate a random 4-digit code
 */
function generateVerificationCode() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

/**
 * Send password reset email with verification code
 * Called from: forgot_password_page.dart
 */
exports.sendPasswordResetCode = functions.https.onCall(async (data, context) => {
  const { email } = data;

  if (!email) {
    throw new functions.https.HttpsError('invalid-argument', 'Email is required');
  }

  try {
    // Check if user exists
    const userRecord = await admin.auth().getUserByEmail(email);

    // Generate verification code
    const verificationCode = generateVerificationCode();
    const expiresAt = Date.now() + VERIFICATION_CODE_EXPIRATION;

    // Store code in Firestore
    await db.collection('passwordReset').doc(email).set({
      code: verificationCode,
      expiresAt: admin.firestore.Timestamp.fromDate(new Date(expiresAt)),
      used: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send email with verification code
    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Culinara - Password Reset Code',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto;">
          <h2 style="color: #5D4A3A;">Password Reset Code</h2>
          <p>Hello,</p>
          <p>You requested to reset your password. Here is your verification code:</p>
          
          <div style="background-color: #F5E6D3; padding: 20px; border-radius: 10px; text-align: center; margin: 20px 0;">
            <h1 style="color: #5D4A3A; letter-spacing: 5px; margin: 0;">
              ${verificationCode.split('').join(' ')}
            </h1>
          </div>
          
          <p>This code will expire in 10 minutes.</p>
          <p>If you didn't request a password reset, please ignore this email.</p>
          
          <p>Thanks,<br/>Culinara Team</p>
        </div>
      `,
    });

    return {
      success: true,
      message: 'Verification code sent to your email',
    };
  } catch (error) {
    console.error('Error sending password reset code:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send verification code'
    );
  }
});

/**
 * Verify the code and reset password
 * Called from: verification_code_page.dart
 */
exports.verifyCodeAndResetPassword = functions.https.onCall(async (data, context) => {
  const { email, verificationCode, newPassword } = data;

  // Validate inputs
  if (!email || !verificationCode || !newPassword) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Email, code, and new password are required'
    );
  }

  if (newPassword.length < 8) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Password must be at least 8 characters'
    );
  }

  try {
    // Get the stored verification code
    const resetDoc = await db.collection('passwordReset').doc(email).get();

    if (!resetDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'No password reset request found for this email'
      );
    }

    const resetData = resetDoc.data();

    // Check if code has expired
    if (resetData.expiresAt.toDate() < new Date()) {
      await db.collection('passwordReset').doc(email).delete();
      throw new functions.https.HttpsError(
        'deadline-exceeded',
        'Verification code has expired. Please request a new one.'
      );
    }

    // Check if code has already been used
    if (resetData.used) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Verification code has already been used'
      );
    }

    // Verify the code
    if (resetData.code !== verificationCode) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Invalid verification code'
      );
    }

    // Get user record
    const userRecord = await admin.auth().getUserByEmail(email);

    // Update password
    await admin.auth().updateUser(userRecord.uid, {
      password: newPassword,
    });

    // Mark code as used
    await db.collection('passwordReset').doc(email).update({
      used: true,
      usedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send confirmation email
    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Culinara - Password Changed',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto;">
          <h2 style="color: #5D4A3A;">Password Successfully Changed</h2>
          <p>Hello,</p>
          <p>Your password has been successfully reset.</p>
          <p>If you did not make this change, please contact support immediately.</p>
          <p>Thanks,<br/>Culinara Team</p>
        </div>
      `,
    });

    return {
      success: true,
      message: 'Password has been reset successfully',
    };
  } catch (error) {
    console.error('Error verifying code and resetting password:', error);
    
    // Re-throw HTTP errors
    if (error.code && error.code.startsWith('functions/')) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      error.message || 'Failed to reset password'
    );
  }
});

/**
 * Verify the code only (without resetting password)
 * Called from: verification_code_page.dart (if needed)
 */
exports.verifyCode = functions.https.onCall(async (data, context) => {
  const { email, verificationCode } = data;

  if (!email || !verificationCode) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Email and code are required'
    );
  }

  try {
    const resetDoc = await db.collection('passwordReset').doc(email).get();

    if (!resetDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'No password reset request found'
      );
    }

    const resetData = resetDoc.data();

    // Check expiration
    if (resetData.expiresAt.toDate() < new Date()) {
      await db.collection('passwordReset').doc(email).delete();
      throw new functions.https.HttpsError(
        'deadline-exceeded',
        'Code has expired'
      );
    }

    // Check if used
    if (resetData.used) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Code has already been used'
      );
    }

    // Verify code
    if (resetData.code !== verificationCode) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Invalid code'
      );
    }

    return {
      success: true,
      message: 'Code verified successfully',
    };
  } catch (error) {
    console.error('Error verifying code:', error);
    
    if (error.code && error.code.startsWith('functions/')) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      error.message || 'Failed to verify code'
    );
  }
});

/**
 * Resend verification code
 * Called from: verification_code_page.dart (Resend button)
 */
exports.resendVerificationCode = functions.https.onCall(async (data, context) => {
  const { email } = data;

  if (!email) {
    throw new functions.https.HttpsError('invalid-argument', 'Email is required');
  }

  try {
    // Check if a recent reset request exists
    const resetDoc = await db.collection('passwordReset').doc(email).get();

    if (!resetDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'No password reset request found. Please start over.'
      );
    }

    const resetData = resetDoc.data();

    // Don't allow resend if code was already used
    if (resetData.used) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'This reset link has already been used'
      );
    }

    // Check if user is trying to spam (less than 30 seconds since last code)
    const lastCreated = resetData.createdAt.toDate();
    const timeSinceLastCode = Date.now() - lastCreated.getTime();
    
    if (timeSinceLastCode < 30 * 1000) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'Please wait 30 seconds before requesting another code'
      );
    }

    // Generate new code
    const newCode = generateVerificationCode();
    const expiresAt = Date.now() + VERIFICATION_CODE_EXPIRATION;

    // Update with new code
    await db.collection('passwordReset').doc(email).update({
      code: newCode,
      expiresAt: admin.firestore.Timestamp.fromDate(new Date(expiresAt)),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send new code
    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Culinara - New Password Reset Code',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto;">
          <h2 style="color: #5D4A3A;">New Password Reset Code</h2>
          <p>Here is your new verification code:</p>
          
          <div style="background-color: #F5E6D3; padding: 20px; border-radius: 10px; text-align: center; margin: 20px 0;">
            <h1 style="color: #5D4A3A; letter-spacing: 5px; margin: 0;">
              ${newCode.split('').join(' ')}
            </h1>
          </div>
          
          <p>This code will expire in 10 minutes.</p>
          <p>Thanks,<br/>Culinara Team</p>
        </div>
      `,
    });

    return {
      success: true,
      message: 'New verification code sent',
    };
  } catch (error) {
    console.error('Error resending verification code:', error);
    
    if (error.code && error.code.startsWith('functions/')) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      error.message || 'Failed to resend code'
    );
  }
});
