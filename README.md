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
