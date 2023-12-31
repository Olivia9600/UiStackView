//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSRecipientIdentity.h"
#import "OWSIdentityManager.h"
#import "OWSPrimaryStorage.h"
#import <SignalCoreKit/Cryptography.h>
#import <BChatMessagingKit/BChatMessagingKit-Swift.h>
#import <YapDatabase/YapDatabase.h>

NS_ASSUME_NONNULL_BEGIN

NSString *OWSVerificationStateToString(OWSVerificationState verificationState)
{
    switch (verificationState) {
        case OWSVerificationStateDefault:
            return @"OWSVerificationStateDefault";
        case OWSVerificationStateVerified:
            return @"OWSVerificationStateVerified";
        case OWSVerificationStateNoLongerVerified:
            return @"OWSVerificationStateNoLongerVerified";
    }
}

@interface OWSRecipientIdentity ()

@property (atomic) OWSVerificationState verificationState;

@end

/**
 * Record for a recipients identity key and some meta data around it used to make trust decisions.
 *
 * NOTE: Instances of this class MUST only be retrieved/persisted via it's internal `dbConnection`,
 *       which makes some special accomodations to enforce consistency.
 */
@implementation OWSRecipientIdentity

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];

    if (self) {
        if (![coder decodeObjectForKey:@"verificationState"]) {
            _verificationState = OWSVerificationStateDefault;
        }
    }

    return self;
}

- (instancetype)initWithRecipientId:(NSString *)recipientId
                        identityKey:(NSData *)identityKey
                    isFirstKnownKey:(BOOL)isFirstKnownKey
                          createdAt:(NSDate *)createdAt
                  verificationState:(OWSVerificationState)verificationState
{
    self = [super initWithUniqueId:recipientId];
    if (!self) {
        return self;
    }
    
    _recipientId = recipientId;
    _identityKey = identityKey;
    _isFirstKnownKey = isFirstKnownKey;
    _createdAt = createdAt;
    _verificationState = verificationState;

    return self;
}

- (void)updateWithVerificationState:(OWSVerificationState)verificationState
                        transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    // Ensure changes are persisted without clobbering any work done on another thread or instance.
    [self updateWithChangeBlock:^(OWSRecipientIdentity *_Nonnull obj) {
        obj.verificationState = verificationState;
    }
                    transaction:transaction];
}

- (void)updateWithChangeBlock:(void (^)(OWSRecipientIdentity *obj))changeBlock
                  transaction:(YapDatabaseReadWriteTransaction *)transaction
{
    changeBlock(self);

    OWSRecipientIdentity *latest = [[self class] fetchObjectWithUniqueID:self.uniqueId transaction:transaction];
    if (latest == nil) {
        [self saveWithTransaction:transaction];
        return;
    }

    changeBlock(latest);
    [latest saveWithTransaction:transaction];
}

- (void)updateWithChangeBlock:(void (^)(OWSRecipientIdentity *obj))changeBlock
{
    changeBlock(self);

    [LKStorage writeSyncWithBlock:^(YapDatabaseReadWriteTransaction *_Nonnull transaction) {
        OWSRecipientIdentity *latest = [[self class] fetchObjectWithUniqueID:self.uniqueId transaction:transaction];
        if (latest == nil) {
            [self saveWithTransaction:transaction];
            return;
        }
        
        changeBlock(latest);
        [latest saveWithTransaction:transaction];
    }];
}

@end

NS_ASSUME_NONNULL_END
