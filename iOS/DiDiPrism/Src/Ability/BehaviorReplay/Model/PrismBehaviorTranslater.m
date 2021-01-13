//
//  PrismBehaviorTranslater.m
//  DiDiPrism
//
//  Created by hulk on 2020/9/27.
//

#import "PrismBehaviorTranslater.h"
#import "NSString+PrismExtends.h"
#import "NSArray+PrismExtends.h"

@interface PrismBehaviorTranslater()

@end

@implementation PrismBehaviorTranslater
#pragma mark - life cycle

#pragma mark - public method
+ (PrismBehaviorTextModel *)translateWithModel:(PrismBehaviorVideoModel *)model {
    PrismBehaviorTextModel *textModel = [[PrismBehaviorTextModel alloc] init];
    textModel.operationName = @"点击";
    textModel.descType = PrismBehaviorDescTypeNone;
    textModel.descTime = model.descTime.length ? model.descTime : @"        ";

    NSArray<NSString*> *eventArray = [model.instructionFormatter instructionFragmentWithType:PrismInstructionFragmentTypeEvent];
    NSArray<NSString*> *h5ViewArray = [model.instructionFormatter instructionFragmentWithType:PrismInstructionFragmentTypeH5View];
    NSArray<NSString*> *viewMotionArray = [model.instructionFormatter instructionFragmentWithType:PrismInstructionFragmentTypeViewMotion];
    NSArray<NSString*> *viewFunctionArray = [model.instructionFormatter instructionFragmentWithType:PrismInstructionFragmentTypeViewFunction];
    NSArray<NSString*> *viewRepresentativeContentArray = [model.instructionFormatter instructionFragmentWithType:PrismInstructionFragmentTypeViewRepresentativeContent];
    NSArray<NSString*> *viewPathArray = [model.instructionFormatter instructionFragmentWithType:PrismInstructionFragmentTypeViewPath];
    
    // 翻译通用事件
    if (eventArray.count) {
        textModel.operationName = @"标记";
        textModel.descType = PrismBehaviorDescTypeText;
        NSMutableString *content = [NSMutableString stringWithString:[self descriptionOfEvent:model.instruction]];
        if (viewRepresentativeContentArray.count > 0 && [viewRepresentativeContentArray[viewRepresentativeContentArray.count - 1] prism_trimmingWhitespaceAndNewlines].length > 0) {
            [content appendFormat:@" %@", viewRepresentativeContentArray[viewRepresentativeContentArray.count - 1]];
        }
        textModel.descContent = [content copy];
        textModel.descTime = @"        ";
        return textModel;
    }
    // 翻译H5指令
    if (h5ViewArray.count) {
        textModel.descType = PrismBehaviorDescTypeText;
        textModel.descContent = @"[H5页面]";
        if (viewRepresentativeContentArray.count > 1 && [viewRepresentativeContentArray[1] prism_trimmingWhitespaceAndNewlines].length > 0) {
            NSString *content = viewRepresentativeContentArray[1];
            if ([self hasNetworkImage:content]) {
                textModel.descType = PrismBehaviorDescTypeNetworkImage;
                textModel.descContent = content;
            }
            else {
                textModel.descContent = [NSString stringWithFormat:@"[H5页面] %@", content];
            }
        }
        return textModel;
    }
    // 翻译触发类型
    NSString *viewMotionType = [viewMotionArray prism_stringWithIndex:1];
    if ([viewMotionType isEqualToString:kViewMotionEdgePanGestureFlag]) {
        textModel.operationName = @"滑动";
        textModel.descType = PrismBehaviorDescTypeText;
        textModel.descContent = @"后退";
        return textModel;
    }
    else if ([viewMotionType isEqualToString:kViewMotionCellFlag]) {
        // 预置为“列表”，如后续有更好的翻译则覆盖。
        textModel.descType = PrismBehaviorDescTypeText;
        textModel.descContent = @"列表";
    }
    // 翻译参考信息和功能信息
    NSArray<NSString*> *contentArray = [[[NSArray array] arrayByAddingObjectsFromArray:viewFunctionArray] arrayByAddingObjectsFromArray:viewRepresentativeContentArray];
    [contentArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self hasChinese:obj]) {
            textModel.descType = PrismBehaviorDescTypeText;
            textModel.descContent = obj;
            *stop = YES;
        }
        else if ([self isOnlyNumber:obj]) {
            textModel.descType = PrismBehaviorDescTypeText;
            textModel.descContent = obj;
            *stop = YES;
        }
        else if ([self hasNetworkImage:obj]) {
            textModel.descType = PrismBehaviorDescTypeNetworkImage;
            textModel.descContent = obj;
            *stop = YES;
        }
    }];
    if (textModel.descType != PrismBehaviorDescTypeNone) {
        return textModel;
    }

    [viewFunctionArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self hasLocalImage:obj]) {
            textModel.descType = PrismBehaviorDescTypeLocalImage;
            textModel.descContent = obj;
            *stop = YES;
        }
    }];
    if (textModel.descType != PrismBehaviorDescTypeNone) {
        return textModel;
    }
    
    // 翻译响应链信息
    [viewPathArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 1 && [self isWindowWith:obj]) {
            textModel.descType = PrismBehaviorDescTypeText;
            textModel.descContent = @"弹窗";
            *stop = YES;
        }
    }];
    
    return textModel;
}

#pragma mark - private method
+ (BOOL)hasChinese:(NSString *)str {
    for(int i=0; i< [str length];i++){
        int a = [str characterAtIndex:i];
        if( a > 0x4e00 && a < 0x9fff)
        {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)isOnlyNumber:(NSString *)str {
    if ([[str prism_trimmingWhitespace] isEqualToString:@"0"] || str.integerValue) {
        return YES;
    }
    return NO;
}

+ (BOOL)hasNetworkImage:(NSString *)str {
    if (([str containsString:@"http://"] || [str containsString:@"https://"])
        && ([str containsString:@".png"] || [str containsString:@".jpg"] || [str containsString:@".jpeg"])) {
        return YES;
    }
    return NO;
}

+ (BOOL)hasLocalImage:(NSString *)str {
    NSString *lastStr = nil;
    NSArray<NSString*> *result = [str componentsSeparatedByString:@"/"];
    if (result.lastObject) {
        lastStr = result.lastObject;
    }
    
    if ([UIImage imageNamed:str] || [UIImage imageNamed:lastStr]) {
        return YES;
    }
    
    for (NSBundle *bundle in [NSBundle allBundles]) {
        UIImage *image = [UIImage imageNamed:lastStr inBundle:bundle compatibleWithTraitCollection:nil];
        if (image) {
            return YES;
        }
    }
    
    return NO;
}

+ (BOOL)isWindowWith:(NSString*)str {
    if ([NSClassFromString(str) isSubclassOfClass:[UIWindow class]]) {
        return YES;
    }
    return NO;
}

+ (NSString*)descriptionOfEvent:(NSString*)event {
    if ([event isEqualToString:kUIApplicationBecomeActive]) {
        return @"APP回到前台";
    }
    else if ([event isEqualToString:kUIApplicationResignActive]) {
        return @"APP切到后台";
    }
    else if ([event containsString:kUIViewControllerDidAppear]) {
        return @"进入页面";
    }
    return nil;
}

#pragma mark - setters

#pragma mark - getters

@end
