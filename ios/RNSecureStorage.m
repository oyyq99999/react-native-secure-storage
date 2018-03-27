#import <Security/Security.h>
#import "RNSecureStorage.h"

#import <LocalAuthentication/LAContext.h>

@implementation RNSecureStorage

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

// Messages from the comments in <Security/SecBase.h>
NSString *messageForError(NSError *error)
{
    switch (error.code) {
        case errSecUnimplemented:
            return @"Function or operation not implemented.";
            
        case errSecIO:
            return @"I/O error.";
            
        case errSecOpWr:
            return @"File already open with with write permission.";
            
        case errSecParam:
            return @"One or more parameters passed to a function were not valid.";
            
        case errSecAllocate:
            return @"Failed to allocate memory.";
            
        case errSecUserCanceled:
            return @"User canceled the operation.";
            
        case errSecBadReq:
            return @"Bad parameter or invalid state for operation.";
            
        case errSecNotAvailable:
            return @"No keychain is available. You may need to restart your computer.";
            
        case errSecDuplicateItem:
            return @"The specified item already exists in the keychain.";
            
        case errSecItemNotFound:
            return @"The specified item could not be found in the keychain.";
            
        case errSecInteractionNotAllowed:
            return @"User interaction is not allowed.";
            
        case errSecDecode:
            return @"Unable to decode the provided data.";
            
        case errSecAuthFailed:
            return @"The user name or passphrase you entered is not correct.";
            
        case errSecMissingEntitlement:
            return @"Internal error when a required entitlement isn't present.";
            
        default:
            return error.localizedDescription;
    }
}

NSString *codeForError(NSError *error)
{
    return [NSString stringWithFormat:@"%li", (long)error.code];
}

void rejectWithError(RCTPromiseRejectBlock reject, NSError *error)
{
    return reject(codeForError(error), messageForError(error), nil);
}

bool isNotNull(NSDictionary *options, NSString *key)
{
    return (options && options[key] != nil && options[key] != (id)[NSNull null]);
}

CFStringRef accessibleValue(NSDictionary *options)
{
    if (isNotNull(options, @"accessible")) {
        NSDictionary *keyMap = @{
                                 @"AccessibleWhenUnlocked": (__bridge NSString *)kSecAttrAccessibleWhenUnlocked,
                                 @"AccessibleAfterFirstUnlock": (__bridge NSString *)kSecAttrAccessibleAfterFirstUnlock,
                                 @"AccessibleAlways": (__bridge NSString *)kSecAttrAccessibleAlways,
                                 @"AccessibleWhenPasscodeSetThisDeviceOnly": (__bridge NSString *)kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                 @"AccessibleWhenUnlockedThisDeviceOnly": (__bridge NSString *)kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                 @"AccessibleAfterFirstUnlockThisDeviceOnly": (__bridge NSString *)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                                 @"AccessibleAlwaysThisDeviceOnly": (__bridge NSString *)kSecAttrAccessibleAlwaysThisDeviceOnly
                                 };
        NSString *result = keyMap[options[@"accessible"]];
        if (result) {
            return (__bridge CFStringRef)result;
        }
    }
    return kSecAttrAccessibleAfterFirstUnlock;
}

NSString *serviceValue(NSDictionary *options)
{
    if (isNotNull(options, @"service")) {
        return options[@"service"];
    }
    return [[NSBundle mainBundle] bundleIdentifier];
}

NSString *accessGroupValue(NSDictionary *options)
{
    if (isNotNull(options, @"accessGroup")) {
        return options[@"accessGroup"];
    }
    return nil;
}

#pragma mark - Proposed functionality - Helpers

#define kAuthenticationType @"authenticationType"
#define kAuthenticationTypeBiometrics @"AuthenticationWithBiometrics"

#define kAccessControlType @"accessControl"
#define kAccessControlUserPresence @"UserPresence"
#define kAccessControlBiometryAny @"BiometryAny"
#define kAccessControlBiometryCurrentSet @"BiometryCurrentSet"
#define kAccessControlDevicePasscode @"DevicePasscode"
#define kAccessControlApplicationPassword @"ApplicationPassword"
#define kAccessControlBiometryAnyOrDevicePasscode @"BiometryAnyOrDevicePasscode"
#define kAccessControlBiometryCurrentSetOrDevicePasscode @"BiometryCurrentSetOrDevicePasscode"

#define kBiometryTypeTouchID @"TouchID"
#define kBiometryTypeFaceID @"FaceID"

#define kAuthenticationPromptMessage @"authenticationPrompt"

LAPolicy authPolicy(NSDictionary *options)
{
    if (options && options[kAuthenticationType]) {
        if ([ options[kAuthenticationType] isEqualToString:kAuthenticationTypeBiometrics ]) {
            return LAPolicyDeviceOwnerAuthenticationWithBiometrics;
        }
    }
    return LAPolicyDeviceOwnerAuthentication;
}

SecAccessControlCreateFlags accessControlValue(NSDictionary *options)
{
    if (options && options[kAccessControlType] && [options[kAccessControlType] isKindOfClass:[NSString class]]) {
        if ([options[kAccessControlType] isEqualToString: kAccessControlUserPresence]) {
            return kSecAccessControlUserPresence;
        }
        else if ([options[kAccessControlType] isEqualToString: kAccessControlBiometryAny]) {
            return kSecAccessControlTouchIDAny;
        }
        else if ([options[kAccessControlType] isEqualToString: kAccessControlBiometryCurrentSet]) {
            return kSecAccessControlTouchIDCurrentSet;
        }
        else if ([options[kAccessControlType] isEqualToString: kAccessControlDevicePasscode]) {
            return kSecAccessControlDevicePasscode;
        }
        else if ([options[kAccessControlType] isEqualToString: kAccessControlBiometryAnyOrDevicePasscode]) {
            return kSecAccessControlTouchIDAny|kSecAccessControlOr|kSecAccessControlDevicePasscode;
        }
        else if ([options[kAccessControlType] isEqualToString: kAccessControlBiometryCurrentSetOrDevicePasscode]) {
            return kSecAccessControlTouchIDCurrentSet|kSecAccessControlOr|kSecAccessControlDevicePasscode;
        }
        else if ([options[kAccessControlType] isEqualToString: kAccessControlApplicationPassword]) {
            return kSecAccessControlApplicationPassword;
        }
    }
    return 0;
}

RCT_EXPORT_METHOD(setItem:(NSString *)key value:(NSString *)value options:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString *service = serviceValue(options);
    NSDictionary *attributes = @{
                                 (__bridge NSString *)kSecClass: (__bridge id)(kSecClassGenericPassword),
                                 (__bridge NSString *)kSecAttrService: service,
                                 (__bridge NSString *)kSecAttrAccount: key,
                                 (__bridge NSString *)kSecValueData: [value dataUsingEncoding:NSUTF8StringEncoding],
                                 };
    [self deleteItemForKey:key inService:service];
    [self insertKeychainEntry:attributes withOptions:options resolver:resolve rejecter:reject];
}

RCT_EXPORT_METHOD(getItem:(NSString *)key options:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString *service = serviceValue(options);
    NSString *authenticationPrompt = @"Authenticate to retrieve secret data";
    if (options && options[kAuthenticationPromptMessage]) {
        authenticationPrompt = options[kAuthenticationPromptMessage];
    }
    NSDictionary *query = @{
                            (__bridge NSString *)kSecClass: (__bridge id)(kSecClassGenericPassword),
                            (__bridge NSString *)kSecAttrService: service,
                            (__bridge NSString *)kSecAttrAccount: key,
                            (__bridge NSString *)kSecReturnAttributes: (__bridge id)kCFBooleanTrue,
                            (__bridge NSString *)kSecReturnData: (__bridge id)kCFBooleanTrue,
                            (__bridge NSString *)kSecUseOperationPrompt: authenticationPrompt,
                            };
    
    // Look up service in the keychain
    NSDictionary *found = nil;
    CFTypeRef foundTypeRef = NULL;
    OSStatus osStatus = SecItemCopyMatching((__bridge CFDictionaryRef) query, (CFTypeRef*)&foundTypeRef);
    
    if (osStatus != noErr && osStatus != errSecItemNotFound) {
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:osStatus userInfo:nil];
        return rejectWithError(reject, error);
    }
    
    found = (__bridge NSDictionary*)(foundTypeRef);
    if (!found) {
        return resolve(nil);
    }
    NSString *value = [[NSString alloc] initWithData:[found objectForKey:(__bridge id)(kSecValueData)] encoding:NSUTF8StringEncoding];
    return resolve(value);
}

RCT_EXPORT_METHOD(removeItem:(NSString *)key options:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString *service = serviceValue(options);
    
    OSStatus osStatus = [self deleteItemForKey:key inService:service];
    
    if (osStatus != noErr && osStatus != errSecItemNotFound) {
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:osStatus userInfo:nil];
        return rejectWithError(reject, error);
    }
    
    return resolve(@(YES));
}

RCT_EXPORT_METHOD(getAllKeys:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString *service = serviceValue(options);
    NSString *authenticationPrompt = @"Authenticate to retrieve secret data";
    if (options && options[kAuthenticationPromptMessage]) {
        authenticationPrompt = options[kAuthenticationPromptMessage];
    }
    
    NSMutableArray* finalResult = [[NSMutableArray alloc] init];
    NSMutableDictionary* query = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                 (__bridge NSString *)kSecClass: (__bridge id)(kSecClassGenericPassword),
                                                                                 (__bridge NSString *)kSecAttrService: service,
                                                                                 (__bridge NSString *)kSecReturnAttributes: (__bridge id)kCFBooleanTrue,
                                                                                 (__bridge NSString *)kSecMatchLimit: (__bridge NSString *)kSecMatchLimitAll,
                                                                                 (__bridge NSString *)kSecReturnData: (__bridge id)kCFBooleanTrue,
                                                                                 (__bridge NSString *)kSecUseOperationPrompt: authenticationPrompt,
                                                                                 }];
    
    CFTypeRef result = NULL;
    OSStatus osStatus = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    
    if (osStatus != noErr && osStatus != errSecItemNotFound) {
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:osStatus userInfo:nil];
        return rejectWithError(reject, error);
    }
    
    if (result != NULL) {
        for (NSDictionary* item in (__bridge id)result) {
            [finalResult addObject:(NSString*)[item objectForKey:(__bridge id)(kSecAttrAccount)]];
        }
    }
    return resolve(finalResult);
}

RCT_EXPORT_METHOD(canCheckAuthentication:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    LAPolicy policyToEvaluate = authPolicy(options);
    
    NSError *aerr = nil;
    BOOL canBeProtected = [[LAContext new] canEvaluatePolicy:policyToEvaluate error:&aerr];
    
    if (aerr || !canBeProtected) {
        return resolve(@(NO));
    } else {
        return resolve(@(YES));
    }
}

RCT_EXPORT_METHOD(getSupportedBiometryType:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSError *aerr = nil;
    LAContext *context = [LAContext new];
    BOOL canBeProtected = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&aerr];
    
    if (!aerr && canBeProtected) {
        if (@available(iOS 11, *)) {
            if (context.biometryType == LABiometryTypeFaceID) {
                return resolve(kBiometryTypeFaceID);
            }
        }
        return resolve(kBiometryTypeTouchID);
    }
    
    return resolve([NSNull null]);
}

- (OSStatus)deleteItemForKey:(NSString *)key inService:(NSString *)service
{
    NSDictionary *query = @{
                            (__bridge NSString *)kSecClass: (__bridge id)(kSecClassGenericPassword),
                            (__bridge NSString *)kSecAttrService: service,
                            (__bridge NSString *)kSecAttrAccount: key,
                            (__bridge NSString *)kSecReturnAttributes: (__bridge id)kCFBooleanTrue,
                            (__bridge NSString *)kSecReturnData: (__bridge id)kCFBooleanFalse,
                            };
    
    return SecItemDelete((__bridge CFDictionaryRef) query);
}

- (void)insertKeychainEntry:(NSDictionary *)attributes withOptions:(NSDictionary * __nullable)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject
{
    NSString *accessGroup = accessGroupValue(options);
    CFStringRef accessible = accessibleValue(options);
    SecAccessControlCreateFlags accessControl = accessControlValue(options);
    
    NSMutableDictionary *mAttributes = attributes.mutableCopy;
    
    if (accessControl) {
        NSError *aerr = nil;
        BOOL canAuthenticate = [[LAContext new] canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&aerr];
        if (aerr || !canAuthenticate) {
            return rejectWithError(reject, aerr);
        }
        
        CFErrorRef error = NULL;
        SecAccessControlRef sacRef = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                                     accessible,
                                                                     accessControl,
                                                                     &error);
        
        if (error) {
            return rejectWithError(reject, aerr);
        }
        mAttributes[(__bridge NSString *)kSecAttrAccessControl] = (__bridge id)sacRef;
    } else {
        mAttributes[(__bridge NSString *)kSecAttrAccessible] = (__bridge id)accessible;
    }
    
    if (accessGroup != nil) {
        mAttributes[(__bridge NSString *)kSecAttrAccessGroup] = accessGroup;
    }
    
    attributes = [NSDictionary dictionaryWithDictionary:mAttributes];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus osStatus = SecItemAdd((__bridge CFDictionaryRef) attributes, NULL);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (osStatus != noErr && osStatus != errSecItemNotFound) {
                NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:osStatus userInfo:nil];
                return rejectWithError(reject, error);
            } else {
                return resolve(@(YES));
            }
        });
    });
    
}

@end
  
