/*
 * opencog/atoms/reduct/TimesLink.cc
 *
 * Copyright (C) 2015, 2018 Linas Vepstas
 * All Rights Reserved
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

#include <opencog/atoms/atom_types/atom_types.h>
#include <opencog/atoms/base/ClassServer.h>
#include <opencog/atoms/core/NumberNode.h>
#include "DivideLink.h"
#include "TimesLink.h"

using namespace opencog;

Handle TimesLink::one;

TimesLink::TimesLink(const HandleSeq&& oset, Type t)
    : ArithmeticLink(std::move(oset), t)
{
	init();
}

TimesLink::TimesLink(const Handle& a, const Handle& b)
    : ArithmeticLink({a,b}, TIMES_LINK)
{
	init();
}

void TimesLink::init(void)
{
	if (nullptr == one) one = createNumberNode(1);
	Type tscope = get_type();
	if (not nameserver().isA(tscope, TIMES_LINK))
		throw InvalidParamException(TRACE_INFO, "Expecting a TimesLink");

	knil = one;
	_commutative = true;
}

// ============================================================

/// Because there is no ExpLink or PowLink that can handle repeated
/// products, or any distributive property, kons is very simple for
/// the TimesLink.
ValuePtr TimesLink::kons(AtomSpace* as, bool silent,
                         const ValuePtr& fi, const ValuePtr& fj) const
{
	if (fj == knil)
		return fi;

	// Try to yank out values, if possible.
	ValuePtr vi(get_value(as, silent, fi));
	Type vitype = vi->get_type();

	ValuePtr vj(get_value(as, silent, fj));
	Type vjtype = vj->get_type();

	// Is either one a TimesLink? If so, then flatten.
	if (TIMES_LINK == vitype or TIMES_LINK == vjtype)
	{
		Handle hi(HandleCast(vi));
		HandleSeq seq;
		// flatten the left
		if (TIMES_LINK == vitype)
		{
			for (const Handle& lhs: hi->getOutgoingSet())
				seq.push_back(lhs);
		}
		else
		{
			seq.push_back(hi);
		}

		// flatten the right
		if (TIMES_LINK == vjtype)
		{
			for (const Handle& rhs: HandleCast(vj)->getOutgoingSet())
				seq.push_back(rhs);
		}
		else
		{
			seq.push_back(HandleCast(vj));
		}
		Handle foo(createLink(std::move(seq), TIMES_LINK));
		TimesLinkPtr ap = TimesLinkCast(foo);
		return ap->delta_reduce(as, silent);
	}

	// Are they numbers? If so, perform vector (pointwise) subtraction.
	// Always lower the strength: Number+Number->Number
	// but FloatValue+Number->FloatValue
	try
	{
		if (NUMBER_NODE == vitype and NUMBER_NODE == vjtype)
			return createNumberNode(times(vi, vj, true));

		return times(vi, vj, true);
	}
	catch (const SilentException& ex)
	{
		// If we are here, they were not simple numbers.
	}

	// If either one is the unit, then just drop it.
	if (NUMBER_NODE == vitype and content_eq(HandleCast(vi), one))
		return sample_stream(vj, vjtype);
	if (NUMBER_NODE == vjtype and content_eq(HandleCast(vj), one))
		return sample_stream(vi, vitype);

   if (nameserver().isA(vjtype, NUMBER_NODE))
   {
      std::swap(vi, vj);
      std::swap(vitype, vjtype);
   }
	// Collapse (3 * (5 / x)) and (13 * (x / 6))
	if (DIVIDE_LINK == vjtype and NUMBER_NODE == vitype)
	{
		Handle dividend(HandleCast(vj)->getOutgoingAtom(0));
		Handle divisor(HandleCast(vj)->getOutgoingAtom(1));
		if (NUMBER_NODE == dividend->get_type())
		{
			Handle hprod(createNumberNode(times(vi, dividend)));
			return createDivideLink(hprod, divisor);
		}
		if (NUMBER_NODE == divisor->get_type())
		{
			Handle hquot(createNumberNode(divide(vi, divisor)));
			if (content_eq(hquot, one))
				return dividend;
			return createTimesLink(hquot, dividend);
		}
	}

	try
	{
		if (NUMBER_NODE == vitype and NUMBER_NODE == vjtype)
			return createNumberNode(times(vi, vj, true));

		return times(vi, vj, true);
	}
	catch (const SilentException& ex)
	{
		// If we are here, they were not simple numbers.
	}

	Handle hi(HandleCast(vi));
	if (nullptr == hi) hi = HandleCast(fi);

	Handle hj(HandleCast(vj));
	if (nullptr == hj) hj = HandleCast(fj);

	// If we are here, we've been asked to multiply two things of the
	// same type, but they are not of a type that we know how to multiply.
	return createTimesLink(hi, hj);
}

DEFINE_LINK_FACTORY(TimesLink, TIMES_LINK)

// ============================================================
