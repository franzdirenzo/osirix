/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - LGPL
  
  See http://www.osirix-viewer.com/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "N3BezierPath.h"
#import "N3Geometry.h"
#import "N3BezierCore.h"
#import "N3BezierCoreAdditions.h"

@interface _N3BezierCoreSteward : NSObject
{
	N3BezierCoreRef _bezierCore;
}

- (id)initWithN3BezierCore:(N3BezierCoreRef)bezierCore;
- (N3BezierCoreRef)N3BezierCore;

@end

@implementation _N3BezierCoreSteward

- (id)initWithN3BezierCore:(N3BezierCoreRef)bezierCore
{
	if ( (self = [super init]) ) {
		_bezierCore	= N3BezierCoreRetain(bezierCore);
	}
	return self;
}

- (N3BezierCoreRef)N3BezierCore
{
	return _bezierCore;
}

- (void)dealloc
{
	N3BezierCoreRelease(_bezierCore);
	_bezierCore = nil;
	[super dealloc];
}
				  
@end



@implementation N3BezierPath

- (id)init
{
    if ( (self = [super init]) ) {
        _bezierCore = N3BezierCoreCreateMutable();
    }
    return self;
}

- (id)initWithBezierPath:(N3BezierPath *)bezierPath
{
    if ( (self = [super init]) ) {
        _bezierCore = N3BezierCoreCreateMutableCopy([bezierPath N3BezierCore]);
		_length = bezierPath->_length;
    }
    return self;
}

- (id)initWithDictionaryRepresentation:(NSDictionary *)dict
{
	if ( (self = [super init]) ) {
		_bezierCore = N3BezierCoreCreateMutableWithDictionaryRepresentation((CFDictionaryRef)dict);
		if (_bezierCore == nil) {
			[self autorelease];
			return nil;
		}
	}
	return self;
}

- (id)initWithN3BezierCore:(N3BezierCoreRef)bezierCore
{
    if ( (self = [super init]) ) {
        _bezierCore = N3BezierCoreCreateMutableCopy(bezierCore);
    }
    return self;
}

- (id)initWithNodeArray:(NSArray *)nodes // array of N3Vectors in NSValues;
{
    N3VectorArray vectorArray;
    NSInteger i;
    
    if ( (self = [super init]) ) {
		if ([nodes count] >= 2) {
			vectorArray = malloc(sizeof(N3Vector) * [nodes count]);
			
			for (i = 0; i < [nodes count]; i++) {
				vectorArray[i] = [[nodes objectAtIndex:i] N3VectorValue];
			}
			
			_bezierCore = N3BezierCoreCreateMutableCurveWithNodes(vectorArray, [nodes count]);
			
			free(vectorArray);
		} else if ([nodes count] == 0) {
			_bezierCore = N3BezierCoreCreateMutable();
		} else {
			_bezierCore = N3BezierCoreCreateMutable();
			N3BezierCoreAddSegment(_bezierCore, CPRMoveToBezierCoreSegmentType, N3VectorZero, N3VectorZero, [[nodes objectAtIndex:0] N3VectorValue]);
			if ([nodes count] > 1) {
				N3BezierCoreAddSegment(_bezierCore, N3LineToBezierCoreSegmentType, N3VectorZero, N3VectorZero, [[nodes objectAtIndex:1] N3VectorValue]);
			}
		}

        
        if (_bezierCore == NULL) {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
	NSDictionary *bezierDict;
	
	bezierDict = [decoder decodeObjectForKey:@"bezierPathDictionaryRepresentation"];
	
	if ( (self = [self initWithDictionaryRepresentation:bezierDict]) ) {
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    N3MutableBezierPath *bezierPath;
    
    bezierPath = [[N3MutableBezierPath allocWithZone:zone] initWithBezierPath:self];
    return bezierPath;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    N3MutableBezierPath *bezierPath;
    
    bezierPath = [[N3MutableBezierPath allocWithZone:zone] initWithBezierPath:self];
    return bezierPath;
}

+ (id)bezierPath
{
    return [[[[self class] alloc] init] autorelease];
}

+ (id)bezierPathWithBezierPath:(N3BezierPath *)bezierPath
{
    return [[[[self class] alloc] initWithBezierPath:bezierPath] autorelease];
}

+ (id)bezierPathN3BezierCore:(N3BezierCoreRef)bezierCore
{
    return [[[[self class] alloc] initWithN3BezierCore:bezierCore] autorelease];
}

- (void)dealloc
{
    N3BezierCoreRelease(_bezierCore);
    _bezierCore = nil;
    N3BezierCoreRandomAccessorRelease(_bezierCoreRandomAccessor);
    _bezierCoreRandomAccessor = nil;
    
    [super dealloc];
}

- (BOOL)isEqualToBezierPath:(N3BezierPath *)bezierPath
{
    if (self == bezierPath) {
        return YES;
    }
    
    return N3BezierCoreEqualToBezierCore(_bezierCore, [bezierPath N3BezierCore]);
}

- (BOOL)isEqual:(id)anObject
{
    if ([anObject isKindOfClass:[N3BezierPath class]]) {
        return [self isEqualToBezierPath:(N3BezierPath *)anObject];
    }
    return NO;
}

- (NSUInteger)hash
{
    return N3BezierCoreSegmentCount(_bezierCore);
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:[self dictionaryRepresentation] forKey:@"bezierPathDictionaryRepresentation"];
}

- (N3BezierPath *)bezierPathByFlattening:(CGFloat)flatness
{
    N3MutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath flatten:flatness];
    return newBezierPath;
}

- (N3BezierPath *)bezierPathBySubdividing:(CGFloat)maxSegmentLength;
{
    N3MutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath subdivide:maxSegmentLength];
    return newBezierPath;
}

- (N3BezierPath *)bezierPathByApplyingTransform:(N3AffineTransform)transform
{
    N3MutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath applyAffineTransform:transform];
    return newBezierPath;
}

- (N3BezierPath *)bezierPathByAppendingBezierPath:(N3BezierPath *)bezierPath connectPaths:(BOOL)connectPaths;
{
    N3MutableBezierPath *newBezierPath;
    newBezierPath = [[self mutableCopy] autorelease];
    [newBezierPath appendBezierPath:bezierPath connectPaths:connectPaths];
    return newBezierPath;
}

- (N3BezierPath *)outlineBezierPathAtDistance:(CGFloat)distance initialNormal:(N3Vector)initalNormal spacing:(CGFloat)spacing;
{
    N3BezierPath *outlinePath;
    N3BezierCoreRef outlineCore;
    
	if (N3BezierCoreSubpathCount(_bezierCore) != 1) {
		return nil;
	}
	
    outlineCore = N3BezierCoreCreateOutline(_bezierCore, distance, spacing, initalNormal);
    outlinePath = [[N3BezierPath alloc] initWithN3BezierCore:outlineCore];
    N3BezierCoreRelease(outlineCore);
    return [outlinePath autorelease];
}

- (NSInteger)elementCount
{
    return N3BezierCoreSegmentCount(_bezierCore);
}

- (CGFloat)length
{
	@synchronized (self) {
		if (_length	== 0.0) {
			_length = N3BezierCoreLength(_bezierCore);
		}
	}
	return _length;
}

- (CGFloat)lengthThroughElementAtIndex:(NSInteger)element
{
    return N3BezierCoreLengthToSegmentAtIndex(_bezierCore, element, N3BezierDefaultFlatness);
}

- (N3BezierCoreRef)N3BezierCore
{
	_N3BezierCoreSteward *bezierCoreSteward;
	N3BezierCoreRef copy;
	copy = N3BezierCoreCreateCopy(_bezierCore);
	bezierCoreSteward = [[_N3BezierCoreSteward alloc] initWithN3BezierCore:copy];
	N3BezierCoreRelease(copy);
	[bezierCoreSteward autorelease];
    return [bezierCoreSteward N3BezierCore];
}

- (NSDictionary *)dictionaryRepresentation
{
	return [(NSDictionary *)N3BezierCoreCreateDictionaryRepresentation(_bezierCore) autorelease];
}

- (N3Vector)vectorAtStart
{
    return N3BezierCoreVectorAtStart(_bezierCore);
}

- (N3Vector)vectorAtEnd
{
    return N3BezierCoreVectorAtEnd(_bezierCore);
}

- (N3Vector)tangentAtStart
{
    return N3BezierCoreTangentAtStart(_bezierCore);
}

- (N3Vector)tangentAtEnd
{
    return N3BezierCoreTangentAtEnd(_bezierCore);
}

- (N3Vector)normalAtEndWithInitialNormal:(N3Vector)initialNormal
{
	if (N3BezierCoreSubpathCount(_bezierCore) != 1) {
		return N3VectorZero;
	}
	
    return N3BezierCoreNormalAtEndWithInitialNormal(_bezierCore, initialNormal);
}

- (N3BezierPathElement)elementAtIndex:(NSInteger)index
{
    return [self elementAtIndex:index control1:NULL control2:NULL endpoint:NULL];
}

- (N3BezierPathElement)elementAtIndex:(NSInteger)index control1:(N3VectorPointer)control1 control2:(N3VectorPointer)control2 endpoint:(N3VectorPointer)endpoint; // Warning: differs from NSBezierPath in that controlVector2 is always the end
{
    N3BezierCoreSegmentType segmentType;
    N3Vector control1Vector;
    N3Vector control2Vector;
    N3Vector endpointVector;
    
    @synchronized (self) {
        if (_bezierCoreRandomAccessor == NULL) {
            _bezierCoreRandomAccessor = N3BezierCoreRandomAccessorCreateWithMutableBezierCore(_bezierCore);
        }
    }
    
    segmentType = N3BezierCoreRandomAccessorGetSegmentAtIndex(_bezierCoreRandomAccessor, index, &control1Vector,  &control2Vector, &endpointVector);
    
    switch (segmentType) {
        case CPRMoveToBezierCoreSegmentType:
            if (endpoint) {
                *endpoint = endpointVector;
            }            
            return CPRMoveToBezierPathElement;
        case N3LineToBezierCoreSegmentType:
            if (endpoint) {
                *endpoint = endpointVector;
            }            
            return N3LineToBezierPathElement;
        case CPRCurveToBezierCoreSegmentType:
            if (control1) {
                *control1 = control1Vector;
            }
            if (control2) {
                *control2 = control2Vector;
            }
            if (endpoint) {
                *endpoint = endpointVector;
            }
            return CPRCurveToBezierPathElement;
		case CPRCloseBezierCoreSegmentType:
            if (endpoint) {
                *endpoint = endpointVector;
            }            
            return CPRCloseBezierPathElement;
    }
    assert(0);
    return 0;
}

- (N3Vector)vectorAtRelativePosition:(CGFloat)relativePosition // RelativePosition is in [0, 1]
{
    N3Vector vector;
    
    if (N3BezierCoreGetVectorInfo(_bezierCore, 0, relativePosition * [self length], N3VectorZero, &vector, NULL, NULL, 1)) {
        return vector;
    } else {
        return [self vectorAtEnd];
    }
}

- (N3Vector)tangentAtRelativePosition:(CGFloat)relativePosition
{
    N3Vector tangent;
    
    if (N3BezierCoreGetVectorInfo(_bezierCore, 0, relativePosition * [self length], N3VectorZero, NULL, &tangent, NULL, 1)) {
        return tangent;
    } else {
        return [self tangentAtEnd];
    }    
}

- (N3Vector)normalAtRelativePosition:(CGFloat)relativePosition initialNormal:(N3Vector)initialNormal
{
    N3Vector normal;
    
	if (N3BezierCoreSubpathCount(_bezierCore) != 1) {
		return N3VectorZero;
	}
	
    if (N3BezierCoreGetVectorInfo(_bezierCore, 0, relativePosition * [self length], initialNormal, NULL, NULL, &normal, 1)) {
        return normal;
    } else {
        return [self normalAtEndWithInitialNormal:initialNormal];
    }    
}

- (CGFloat)relalativePositionClosestToVector:(N3Vector)vector
{
    return N3BezierCoreRelativePositionClosestToVector(_bezierCore, vector, NULL, NULL);
}

- (CGFloat)relalativePositionClosestToLine:(N3Line)line;
{
    return N3BezierCoreRelativePositionClosestToLine(_bezierCore, line, NULL, NULL);
}

- (CGFloat)relalativePositionClosestToLine:(N3Line)line closestVector:(N3VectorPointer)vectorPointer;
{
    return N3BezierCoreRelativePositionClosestToLine(_bezierCore, line, vectorPointer, NULL);
}

- (N3BezierPath *)bezierPathByCollapsingZ
{
    N3MutableBezierPath *collapsedBezierPath;
    N3AffineTransform collapseTransform;
    
    collapsedBezierPath = [self mutableCopy];
    
    collapseTransform = N3AffineTransformIdentity;
    collapseTransform.m33 = 0.0;
    
    [collapsedBezierPath applyAffineTransform:collapseTransform];
    
    return [collapsedBezierPath autorelease];
}

- (NSArray*)intersectionsWithPlane:(N3Plane)plane // returns NSNumbers of the relativePositions of the intersections with the plane.
{
	N3MutableBezierPath *flattenedPath;
	N3BezierCoreRef bezierCore;
	NSInteger intersectionCount;
	NSInteger i;
	NSMutableArray *intersectionArray;
	CGFloat *relativePositions;
	
	flattenedPath = [self mutableCopy];
	[flattenedPath subdivide:N3BezierDefaultSubdivideSegmentLength];
	[flattenedPath flatten:N3BezierDefaultFlatness];
	
	bezierCore = [flattenedPath N3BezierCore];
	intersectionCount = N3BezierCoreCountIntersectionsWithPlane(bezierCore, plane);
	relativePositions = malloc(intersectionCount * sizeof(CGFloat));
	
	intersectionCount = N3BezierCoreIntersectionsWithPlane(bezierCore, plane, NULL, relativePositions, intersectionCount);
	
	intersectionArray = [NSMutableArray arrayWithCapacity:intersectionCount];
	for (i = 0; i < intersectionCount; i++) {
		[intersectionArray addObject:[NSNumber numberWithDouble:relativePositions[i]]];
	}
	
	free(relativePositions);
	[flattenedPath release];
	
	return intersectionArray;
}

@end

@interface N3MutableBezierPath ()

- (void)_clearRandomAccessor;

@end


@implementation N3MutableBezierPath

- (void)moveToVector:(N3Vector)vector
{
    [self _clearRandomAccessor];
    N3BezierCoreAddSegment(_bezierCore, CPRMoveToBezierPathElement, N3VectorZero, N3VectorZero, vector);
}

- (void)lineToVector:(N3Vector)vector
{
    [self _clearRandomAccessor];
    N3BezierCoreAddSegment(_bezierCore, N3LineToBezierPathElement, N3VectorZero, N3VectorZero, vector);
}

- (void)curveToVector:(N3Vector)vector controlVector1:(N3Vector)controlVector1 controlVector2:(N3Vector)controlVector2
{
    [self _clearRandomAccessor];
    N3BezierCoreAddSegment(_bezierCore, CPRCurveToBezierPathElement, controlVector1, controlVector2, vector);
}

- (void)close
{
	[self _clearRandomAccessor];
    N3BezierCoreAddSegment(_bezierCore, CPRCloseBezierPathElement, N3VectorZero, N3VectorZero, N3VectorZero);
}

- (void)flatten:(CGFloat)flatness
{
    [self _clearRandomAccessor];
    N3BezierCoreFlatten(_bezierCore, flatness);
}

- (void)subdivide:(CGFloat)maxSegmentLength;
{
    [self _clearRandomAccessor];
    N3BezierCoreSubdivide(_bezierCore, maxSegmentLength);
}

- (void)applyAffineTransform:(N3AffineTransform)transform
{
    [self _clearRandomAccessor];
    N3BezierCoreApplyTransform(_bezierCore, transform);
}

- (void)appendBezierPath:(N3BezierPath *)bezierPath connectPaths:(BOOL)connectPaths
{
    [self _clearRandomAccessor];
    N3BezierCoreAppendBezierCore(_bezierCore, [bezierPath N3BezierCore], connectPaths);
}

- (void)_clearRandomAccessor
{
    N3BezierCoreRandomAccessorRelease(_bezierCoreRandomAccessor);
    _bezierCoreRandomAccessor = NULL;
	_length = 0.0;
}

- (void)setVectorsForElementAtIndex:(NSInteger)index control1:(N3Vector)control1 control2:(N3Vector)control2 endpoint:(N3Vector)endpoint
{
	[self elementAtIndex:index]; // just to make sure that the _bezierCoreRandomAccessor has been initialized
	N3BezierCoreRandomAccessorSetVectorsForSegementAtIndex(_bezierCoreRandomAccessor, index, control1, control2, endpoint);
}

@end

















