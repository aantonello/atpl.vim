/**
 * \file
 * Defines the <{$BASENAME$}> Objective-C interface class.
 *
 * \author  <{@AUTHOR@}> <{@AUTHORMAIL@}>
 * \date    <{$LOCALDATE$}>
 * \since   <{@PROJECT@}> <{@VERSION@}>
 *
 * \copyright <{$YEAR$}>, <{@OWNER@}>. All rights reserved.
 */
#import "<{$BASENAME$}>.h"

/* ===========================================================================
 * <{$BASENAME$}> IMPLEMENTATION
 * ======================================================================== */
@implementation <{$BASENAME$}>
/* ------------------------------------------------------------------------ */
/*! \name INITIALIZATION *//*{{{*/ //@{
/* ------------------------------------------------------------------------ */

/**
 * The initialization function.
 *//* --------------------------------------------------------------------- */
- (id)init
{
    self = [super init];
    return self;
}
///@} INITIALIZATION /*}}}*/
/* ------------------------------------------------------------------------ */
/*! \name NSObject OVERRIDES *//*{{{*/ //@{
/* ------------------------------------------------------------------------ */

/**
 * Deallocation function.
 * Deallocate any memory allocated for this object instance.
 *//* --------------------------------------------------------------------- */
- (void)dealloc
{
    /* Call super::dealloc() in the end. */
    [super dealloc];
}
///@} NSObject OVERRIDES /*}}}*/
/* ------------------------------------------------------------------------ */
@end
// vim:syntax=objc.doxygen
