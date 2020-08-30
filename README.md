# cloud-resume-challenge

This is a project making use of AWS and Terraform to
host my CV at <https://cv.bernardting.com>, inspired by
<https://cloudresumechallenge.dev/instructions/>.

## Application architecture

The frontend consists of HTML and JavaScript, while the backend is
written in Python.

## Build pipeline

This project is built using [GitHub
Actions](https://github.com/benating/cloud-resume-challenge/actions),
which plans and applies the latest Terraform infrastructure.

## Linting

This project uses pre-commit to run linting on most files through tools
like [black](https://github.com/psf/black). To get these to run
automatically on each commit, install [pre-commit](https://pre-commit.com).

This project also makes use of [commitlint](https://commitlint.js.org/#/)
and follows the
[conventional commits](https://www.conventionalcommits.org/en/v1.0.0/) format.
