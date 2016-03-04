---
layout: post
title: "Rails API Tips: Embrace Exceptions"
author: bschaeffer
date: 2016/03/04 15:22:00 EST
tags: rails, api, tips, ruby
excerpt: >
  Today, in our first ever blog post, we look at error and exception handling
  inside your Rails API application.
---

100% of the applications you build will encounter errors. The trick is being
able to handle them and _fail gracefully_. When it comes to building Rails APIs,
handling exceptions is actually really easy when you embrace the `!`. Today, in
our first blog post ever, we're going to do just that.

Before we start, there's actually a lot that's already been written on this
subject, and I'd like to point you to [a post by Avdi Grimm][avdi-ex] which
ended up leading me to his book, [Exceptional Ruby][avdi-book]. If you're
interested in diving deeper, I can't recommend it enough.

In the post itself, Avdi shares an email from the late Jim Weirich on the topic,
with this small snippet being really important for us today.

> Most exception handlers should be generic. Since exceptions indicate a failure
  of some type, then the handler needs only make a decision on what to do in
  case of failure.

In other words: know it's coming, handle it and move on with your life.

When it comes to building a Rails API, this concept is ridiculously easy to
follow.

## Let's raise some exceptions

Actually, for our first example, let's not:

{% highlight ruby %}
def create
  if can?(:create, User)
    user = User.new(user_params)
    if user.save
      render json: user, status: 201
    else
      render json: {errors: user.errors.full_messages}, status: 422
    end
  else
    render json: {errors: 'You are unauthorized.'}, status: 401
  end
end
{% endhighlight %}

There are few things I'd like to point here:

1. ActiveRecord's `save` method [only rescues `RecordInvalid`][ar-save]
   exceptions. So, while you've avoided that, you haven't planned for anything
   else to go wrong. Since we know that something else will go wrong, we need to
   have a better plan.

2. Handling and displaying validation errors is pretty common, so you're going
   to be duplicating this code throughout your application and we really want to
   avoid that.

3. We've given a lot of responsibility to one single controller method here. It
   is expected to either **a)** return an unauthorized access message, **b)**
   return validation error message, or **c)** respond with the newly created
   user object if everything works out.

There's got to be a better way to separate our concerns here.

## `rescue_from` to the rescue

To avoid duplicating our effort to return nice validation and authorization
errors to the client, we're going embrace exceptions here and take advantage of
the [`rescue_from`][as-rescue] helper method.

```ruby
module Api
  class BaseController < ActionController::Base
    rescue_from ActiveRecord::RecordInvalid,
      with: :handle_validation_error

    rescue_from CanCan::Unauthorized,
      with: :handle_authorization_error

    private

    def handle_validation_error(e)
      render json: {errors: e.record.errors.full_messages}, status: 422
    end

    def handle_authorization_error
      render json: {message: "You are unauthorized."}, status: 401
    end
  end

  class UsersController < BaseController
    def create
      authorize! :create, User
      user = User.create!(user_params)
      render json: user, status: 201
    end
  end
end
```

This is much better for many reasons:

1. The `#create` method definition more clearly communicates its purpose. Ensure
   authorization, create a record and render it back to the client.

3. We've separated our concerns and followed Jim Weirich's principle. Our
   exception handling code only comes into play when there is a point of
   failure and our controller code doesn't have to worry about making any of
   those decisions.

2. Any controller inheriting from `BaseController` now get's generic exception
   handling for free.

It took me a while to catch on to the idea, but I rarely (if ever) use
_soft save_ methods any more. Of course, there will always be exceptions to this
idea, but I think this pattern fits perfectly into Rails API development.

[avdi-ex]: http://devblog.avdi.org/2014/05/21/jim-weirich-on-exceptions/ "Jim Weirich on Ruby Exceptions"
[avdi-book]: http://exceptionalruby.com/ "Exception Ruby eBook"
[ar-save]: https://github.com/rails/rails/blob/5d1402a1011f58b405e42007d3ceed4e122d273e/activerecord/lib/active_record/persistence.rb#L119
[as-rescue]: http://api.rubyonrails.org/classes/ActiveSupport/Rescuable/ClassMethods.html#method-i-rescue_from
