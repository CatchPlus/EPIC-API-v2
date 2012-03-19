package org.sara.epic.xml;

import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import net.handle.hdllib.HandleValue;

/**
 * A set of handle {@link Value}s. Duplicate indices ({@link Value#idx}) are not
 * allowed.
 * 
 * @author Markus.vanDijk@sara.nl
 */
public class ValueSet implements Collection<Value>, Iterable<Value> {
	private final Map<Integer, Value> map;

	public ValueSet() {
		map = new HashMap<Integer, Value>();
	}

	/**
	 * Retrieve handle data by index.
	 * 
	 * @param idx
	 *            value for index field of handle data
	 * @return the handle data with this index, or <code>null</code> if not
	 *         present
	 * @throws NullPointerException
	 *             if <code>idx</code> is <code>null</code>
	 */
	public Value get(Integer idx) {
		return map.get(idx);
	}

	/**
	 * Retrieve handle data by index.
	 * 
	 * @param idx
	 *            value for index field of handle data
	 * @return the handle data with this index, or <code>null</code> if not
	 *         present
	 */
	public Value get(int idx) {
		return get(Integer.valueOf(idx));
	}

	/**
	 * Adds handle data to this collection.
	 * 
	 * @param value
	 *            data to be added
	 * @return <code>true</code> if this collection changed as a result of the
	 *         call
	 * @throws NullPointerException
	 *             if <code>value</code> is <code>null</code>
	 * @throws IllegalArgumentException
	 *             if some property of the element prevents it from being added
	 *             to this collection
	 * @see #add(Value)
	 */
	public boolean add(HandleValue value) {
		return add(new Value(value));
	}

	/**
	 * Adds handle data to this collection.
	 * 
	 * @param value
	 *            data to be added
	 * @return <code>true</code> if this collection changed as a result of the
	 *         call
	 * @throws NullPointerException
	 *             if <code>value</code> is <code>null</code>
	 * @throws IllegalArgumentException
	 *             if some property of the element prevents it from being added
	 *             to this collection
	 * @see Collection#add(Object)
	 */
	@Override
	public boolean add(Value value) {
		if (value == null) {
			throw new NullPointerException();
		}

		// if the value is already present, do nothing and return false
		if (map.containsValue(value)) {
			return false;
		}

		// it is an error if the index is already taken
		Integer key = Integer.valueOf(value.idx);
		if (map.containsKey(key)) {
			throw new IllegalArgumentException();
		}

		// OK add
		map.put(key, value);
		return true;
	}

	@Override
	public Iterator<Value> iterator() {
		return map.values().iterator();
	}

	@Override
	public void clear() {
		map.clear();
	}

	/**
	 * Returns true if this collection contains a handle value with the
	 * specified index.
	 * 
	 * @param index
	 *            whose presence in this collection is to be tested
	 * @return <code>true</code> if this collection contains a value with the
	 *         specified index
	 * @throws NullPointerException
	 *             <code>index</code> is <code>null</code>
	 * @see Collection#contains(Object)
	 */
	public boolean contains(Integer index) {
		return map.containsKey(index);
	}

	/**
	 * Returns true if this collection contains a handle value with the
	 * specified index.
	 * 
	 * @param index
	 *            whose presence in this collection is to be tested
	 * @return <code>true</code> if this collection contains a value with the
	 *         specified index
	 * @throws NullPointerException
	 *             <code>value</code> is <code>null</code>
	 * @see Collection#contains(Object)
	 */
	public boolean contains(int index) {
		return contains(Integer.valueOf(index));
	}

	/**
	 * Returns true if this collection contains the specified element.
	 * 
	 * @param value
	 *            whose presence in this collection is to be tested
	 * @return <code>true</code> if this collection contains the specified value
	 * @throws NullPointerException
	 *             <code>value</code> is <code>null</code>
	 * @see Collection#contains(Object)
	 */
	public boolean contains(Value value) {
		return map.containsValue(value);
	}

	/**
	 * @deprecated use {@link #contains(Value)}
	 */
	@Deprecated
	@Override
	public boolean contains(Object o) {
		return map.containsValue(o);
	}

	@Override
	public boolean isEmpty() {
		return map.isEmpty();
	}

	@Override
	public int size() {
		return map.size();
	}

	/**
	 * @deprecated operation not supported
	 * @throws UnsupportedOperationException
	 */
	@Deprecated
	@Override
	public boolean remove(Object o) {
		throw new UnsupportedOperationException();
	}

	/**
	 * @deprecated operation not supported
	 * @throws UnsupportedOperationException
	 */
	@Deprecated
	@Override
	public boolean addAll(Collection<? extends Value> c) {
		throw new UnsupportedOperationException();
	}

	/**
	 * @deprecated operation not supported
	 * @throws UnsupportedOperationException
	 */
	@Deprecated
	@Override
	public boolean containsAll(Collection<?> c) {
		throw new UnsupportedOperationException();
	}

	/**
	 * @deprecated operation not supported
	 * @throws UnsupportedOperationException
	 */
	@Deprecated
	@Override
	public boolean removeAll(Collection<?> c) {
		throw new UnsupportedOperationException();
	}

	/**
	 * @deprecated operation not supported
	 * @throws UnsupportedOperationException
	 */
	@Deprecated
	@Override
	public boolean retainAll(Collection<?> c) {
		throw new UnsupportedOperationException();
	}

	/**
	 * @deprecated operation not supported
	 * @throws UnsupportedOperationException
	 */
	@Deprecated
	@Override
	public Object[] toArray() {
		throw new UnsupportedOperationException();
	}

	/**
	 * @deprecated operation not supported
	 * @throws UnsupportedOperationException
	 */
	@Deprecated
	@Override
	public <T> T[] toArray(T[] a) {
		throw new UnsupportedOperationException();
	}

}