//
//  Stream.swift
//  RxSwift
//
//  Created by Justin Spahr-Summers on 2014-06-03.
//  Copyright (c) 2014 GitHub. All rights reserved.
//

import Foundation
 
operator infix |> { associativity left }

/// Combines a stream-of-streams into a single stream, using the given policy
/// function.
///
/// This allows code like:
///
///		let sss: Stream<Stream<Stream<T>>>
///		let s = concat(flatten(s))
///
/// to instead be written like:
///
///		let s = s |> flatten |> concat
///
///	This isn't a method within the `Stream` class because it's only valid on
///	streams-of-streams.
@infix func |><T>(stream: Stream<Stream<T>>, f: Stream<Stream<T>> -> Stream<T>) -> Stream<T> {
	return f(stream)
}

/// A monadic stream of `Event<T>`.
class Stream<T> {
	/// Creates an empty stream.
	class func empty() -> Stream<T> {
		return Stream()
	}
	
	/// Creates a stream with a single value.
	class func single(T) -> Stream<T> {
		return Stream()
	}

	/// Scans over the stream, accumulating a state and mapping each value to
	/// a new stream, then flattens all the resulting streams into one.
	///
	/// This is rarely useful directly—it's just a primitive from which many
	/// convenient stream operators can be derived.
	func flattenScan<S, U>(initial: S, f: (S, T) -> (S?, Stream<U>)) -> Stream<U> {
		return .empty()
	}

	/// Lifts the given function over the values in the stream.
	@final func map<U>(f: T -> U) -> Stream<U> {
		return flattenScan(0) { (_, x) in (0, .single(f(x))) }
	}

	/// Keeps only the values in the stream that match the given predicate.
	@final func filter(pred: T -> Bool) -> Stream<T> {
		return map { x in pred(x) ? .single(x) : .empty() }
			|> flatten
	}

	/// Takes only the first `count` values from the stream.
	///
	/// If `count` is longer than the length of the stream, the entire stream is
	/// returned.
	@final func take(count: Int) -> Stream<T> {
		if (count == 0) {
			return .empty()
		}

		return flattenScan(0) { (n, x) in
			if n < count {
				return (n + 1, .single(x))
			} else {
				return (nil, .empty())
			}
		}
	}

	/// Skips the first `count` values in the stream.
	///
	/// If `count` is longer than the length of the stream, an empty stream is
	/// returned.
	@final func skip(count: Int) -> Stream<T> {
		return flattenScan(0) { (n, x) in
			if n < count {
				return (n + 1, .empty())
			} else {
				return (count, .single(x))
			}
		}
	}
}

/// Flattens a stream-of-streams into a single stream of values.
///
/// The exact manner in which flattening occurs is determined by the
/// stream's implementation of `flattenScan()`.
func flatten<T>(stream: Stream<Stream<T>>) -> Stream<T> {
	return stream.flattenScan(0) { (_, s) in (0, s) }
}
