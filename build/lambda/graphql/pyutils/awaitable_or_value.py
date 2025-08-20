from collections.abc import Awaitable
from typing import TypeVar, Union

__all__ = ["AwaitableOrValue"]


T = TypeVar("T")

AwaitableOrValue = Union[Awaitable[T], T]
