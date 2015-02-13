### ConcernExpose

This repo contains a simple script in the `lib/` folder and can be run
with Ruby `v2.1.x`

```
$ bundle
$ rails runner lib/scripts/concerns.rb
```

To yield the following results

```
-> % rails runner lib/scripts/concerns.rb
Concern#appended_features:
lib/scripts/concerns.rb:136:in `include'
lib/scripts/concerns.rb:136:in `<class:C>'
> Base: C
> Receiver (self): A

A.append_features: mod=C, self=A

Concern#included: A included in C

Concern#appended_features:
lib/scripts/concerns.rb:137:in `include'
lib/scripts/concerns.rb:137:in `<class:C>'
> Base: C
> Receiver (self): B

D.append_features: mod=C, self=D

This is the included block in module C!
Meaning of life and the universe? => 42

B.append_features: mod=C, self=B

Concern#included: B included in C

C's ancestors: [C, B, D, A]
Calling C#get_ivar...
> D#get_ivar: 'I'm instance #<C:0x007f8b3a786618>' (self = C)!
```

I recommend comparing the above with notes detailed within the
`concerns.rb` file.

### References

1. https://www.ruby-forum.com/topic/4405944
2. https://github.com/rails/rails/blob/f37ad331089f64ab0386e8ac94b6626b45c38a1e/activesupport/lib/active_support/concern.rb
