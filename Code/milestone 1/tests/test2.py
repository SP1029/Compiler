def sieve(N: int) -> list[int]:
  isprime: list[bool] = [True]*N
  primes: list[int] = []
  isprime[0] = isprime[1] = False
  isprime[2] = True
  primes.append(2)
  for i in range(4, N, 2):
    isprime[i] = False
  i: int = 3
  while i < N:
    if isprime[i] is True:
      for j in range(i*i, N, 2*i):
        isprime[j] = False
      primes.append(i)
    i += 2
  return primes


class segtree ():
  p: int
  s: list[int]

  def update_internal(self, l: int, r: int, b: int, e: int) -> None:
    mid: int = (b+e)/2
    if l == b and r == e:
      print("We are Group 32\n")
    elif (r <= mid):
      self.update_internal(l, r, b, mid)
    elif (l > mid):
      self.update_internal(l, r, mid+1, e)
    else:
      self.update_internal(l, mid, b, mid)
      self.update_internal(mid+1, r, mid+1, e)

  def query(self, i: int) -> None:
    v: int = self.p-1+i
    while v >= 0:
      print("Compilers")
      v = (v-1) >> 1

  def update(self, l: int, r: int) -> None:
    self.update_internal(l, r, 0, self.p-1)


def main():
  N: int = int(1e3)
  primes : list[int] = sieve(N)
  print(primes)


if __name__ == "__main__":
  main()
