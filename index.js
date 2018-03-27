
import { NativeModules, Platform } from 'react-native';

const { RNSecureStorage } = NativeModules;

export const ACCESSIBLE = {
  WHEN_UNLOCKED: 'AccessibleWhenUnlocked',
  AFTER_FIRST_UNLOCK: 'AccessibleAfterFirstUnlock',
  ALWAYS: 'AccessibleAlways',
  WHEN_PASSCODE_SET_THIS_DEVICE_ONLY: 'AccessibleWhenPasscodeSetThisDeviceOnly',
  WHEN_UNLOCKED_THIS_DEVICE_ONLY: 'AccessibleWhenUnlockedThisDeviceOnly',
  AFTER_FIRST_UNLOCK_THIS_DEVICE_ONLY:
    'AccessibleAfterFirstUnlockThisDeviceOnly',
  ALWAYS_THIS_DEVICE_ONLY: 'AccessibleAlwaysThisDeviceOnly',
};

export const ACCESS_CONTROL = {
  USER_PRESENCE: 'UserPresence',
  BIOMETRY_ANY: 'BiometryAny',
  BIOMETRY_CURRENT_SET: 'BiometryCurrentSet',
  DEVICE_PASSCODE: 'DevicePasscode',
  APPLICATION_PASSWORD: 'ApplicationPassword',
  BIOMETRY_ANY_OR_DEVICE_PASSCODE: 'BiometryAnyOrDevicePasscode',
  BIOMETRY_CURRENT_SET_OR_DEVICE_PASSCODE: 'BiometryCurrentSetOrDevicePasscode',
};

export const AUTHENTICATION_TYPE = {
  DEVICE_PASSCODE_OR_BIOMETRICS: 'AuthenticationWithBiometricsDevicePasscode',
  BIOMETRICS: 'AuthenticationWithBiometrics',
};

export const BIOMETRY_TYPE = {
  TOUCH_ID: 'TouchID',
  FACE_ID: 'FaceID',
  FINGERPRINT: 'Fingerprint',
};

const isAndroid = Platform.OS === 'android'

const defaultOptions = {
  accessControl: null,
  accessible: ACCESSIBLE.WHEN_UNLOCKED,
  accessGroup: null,
  authenticationPrompt: 'Authenticate to retrieve secret data',
  service: null,
  authenticateType: AUTHENTICATION_TYPE.DEVICE_PASSCODE_OR_BIOMETRICS,
}

export default {
  getItem(key, options) {
    const finalOptions = {
      ...defaultOptions,
      ...options,
    }
    if (isAndroid) {
      return RNSecureStorage.getItem(key, finalOptions.service)
    }
    return RNSecureStorage.getItem(key, finalOptions)
  },
  setItem(key, value, options) {
    const finalOptions = {
      ...defaultOptions,
      ...options,
    }
    if (isAndroid) {
      return RNSecureStorage.setItem(key, value, finalOptions.service)
    }
    return RNSecureStorage.setItem(key, value, finalOptions)
  },
  removeItem(key, options) {
    const finalOptions = {
      ...defaultOptions,
      ...options,
    }
    if (isAndroid) {
      return RNSecureStorage.removeItem(key, finalOptions.service)
    }
    return RNSecureStorage.removeItem(key, finalOptions)
  },
  getAllKeys(options) {
    const finalOptions = {
      ...defaultOptions,
      ...options,
    }
    if (isAndroid) {
      return RNSecureStorage.getAllKeys(finalOptions.service)
    }
    return RNSecureStorage.getAllKeys(finalOptions)
  },
  getSupportedBiometryType() {
    return RNSecureStorage.getSupportedBiometryType()
  },
  canCheckAuthentication(options) {
    const finalOptions = {
      ...defaultOptions,
      ...options,
    }
    if (isAndroid) {
      return RNSecureStorage.getSupportedBiometryType() !== null
    }
    return RNSecureStorage.canCheckAuthentication(options)
  },
}
