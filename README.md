
## How can I find the ID of my blog post on dev.to?

This repository is made to **edit** a blog post. Whether it's published or just a draft, you **have to create it** on dev.to directly. Unfortunately, dev.to does not display the ID of the blog post on the page. So once it's created, you can open your browser console and paste the following code to retrieve the blog post ID:  
`$('div[data-article-id]').getAttribute('data-article-id')`

## References
- [Manage your dev.to blog posts from a GIT repo and use continuous deployment to auto publish/update them](https://dev.to/maxime1992/manage-your-dev-to-blog-posts-from-a-git-repo-and-use-continuous-deployment-to-auto-publish-update-them-143j)

## How do I configure every blog post individually?

A blog post has to have a [**front matter**](https://dev.to/p/editor_guide) header. You can find an example in this repository here: https://github.com/maxime1992/dev.to/blob/master/blog-posts/name-of-your-blog-post/name-of-your-blog-post.md

Simple and from there you have control over the following properties: `title`, `published`, `cover_image`, `description`, `tags`, `series` and `canonical_url`.

# Amin's blog source

https://dev.to/amin

## Blog posts

- [Playing with Spotify API and Auth0](https://dev.to/amin/test-article-378c-temp-slug-32821)
