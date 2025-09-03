def power_two(x: int) -> int:
  return (1 << x)

def gcd(a: int, b: int) -> int:
  if a < b:
    return gcd(b, a)
  else:
    if a%b == 0:
      return b
    else:
      return gcd(b, a%b)

def lcm(a: int, b: int) -> int:
  return a*b//gcd(a, b)


def countGreater(arr: list[int], n: int, k: int) -> int:
  l: int = 0
  r: int = n - 1
  leftGreater: int = n
  while (l <= r):
    m: int = int(l + (r - l) / 2)
    if (arr[m] >= k):
      leftGreater = m
      r = m - 1
    else:
      l = m + 1
      return (n - leftGreater)


def lower_bound(arr: list[int], n: int, val: int) -> int:
  l: int = -1
  r: int = n
  while r > l+1:
    m: int = int((l+r) >> 1)
    if arr[m] < val:
      l = m
    else:
      r = m
  return r


def upper_bound(arr: list[int], n: int, val: int) -> int:
  l: int = -1
  r: int = n
  while r > l+1:
    m: int = int((l+r) >> 1)
    if arr[m] <= val:
      l = m
    else:
      r = m
  return l


def binpow(a: int, n: int, mod: int) -> int:
  res: int = 1
  while n:
    if n & 1:
      res = (res*a) % mod
      n -= 1
    a = (a*a) % mod
    n = n >> 1
  return res


def printmat(l:list[int], seperate: bool) -> None:
  for i in range(0, len(l)):
    if (seperate):
      print(l[i], sep=" ")
    else:
      print(l[i], sep="")


def is_perfect_square(num: int) -> bool:
  temp : float = num**(0.5)
  return (temp//1) == temp


def sqrt() -> int:
  return 1


def euler_totient(n: int) -> int:
  res: int = n
  for i in range(2, int(sqrt(n))+1):
    if res % i == 0:
      while n % i == 0:
        n = n//i

      res = res-res//i
  if n > 1:
    res = res-res//n
  return res


def custom_ceil(a: int, b: int) -> int:
  return (a+b-1)//b


def iter_dfs(node: int, comp: int) -> bool:
  stk: list[int] = [node]
  vis: list[bool] = [False]*(comp+1)
  graph: list[int]
  while len(stk):
    node = stk[-1]
    vis[node] = True
    for child in graph[node]:
      if child == comp:
        return True
      if vis[child] == False:
        vis[child] = True
        stk.append(child)
  return False


class FindArea():
  def findhist(self, row:list[int]) -> int:
    result: list[int] = []
    top_val: int = 0
    max_area: int = 0
    area: int = 0
    i: int = 0
    while (i < len(row)):
      if (len(result) == 0) or (row[result[-1]] <= row[i]):
        result.append(i)
        i += 1
      else:
        top_val = row[result.pop()]
        area = top_val * i
        if (len(result)):
          area = top_val * (i - result[-1] - 1)
        max_area = max(area, max_area)
    while (len(result)):
      top_val = row[result.pop()]
      area = top_val * i
      if (len(result)):
        area = top_val * (i - result[-1] - 1)
      max_area = max(area, max_area)
    return max_area


def solve(cnt: int) -> None:
  n: int = 5
  a: list[int] = [1, 2, 3, 4, 5]
  s: int = 0
  od: int = 0
  ev: int = 0
  for i in range(n):
    s += a[i]
    od += (a[i] & 1)
    ev += (a[i] & 1 == 0)
    if i == 0:
      print(s, end=' ')


def main():
  tc: int = 7
  cnt: int = 5
  while tc:
    solve(cnt)
    tc -= 1
    cnt += 1


if __name__ == "__main__":
  main()
