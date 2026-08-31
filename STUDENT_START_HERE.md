# Start Here

This folder is the complete workshop directory.

## Before the workshop

1. Download and unzip the folder.
2. Move the unzipped folder somewhere simple, for example your Desktop or Documents folder.
3. Open RStudio.
4. In RStudio, open `SDM_dengue_Brazil_workshop.Rproj`.
5. Run `scripts/00_student_setup_before_workshop.R`.
6. Check that the script says the required packages and data files are ready.

Opening the `.Rproj` file makes this folder your working directory automatically.

## During the workshop

Open:

`scripts/workshop_aedes_aegypti_brazil_sdm.R`

We will run this script line by line together.

## If the working directory is wrong

In RStudio, go to:

Session > Set Working Directory > Choose Directory...

Then choose the unzipped `SDM_dengue_Brazil_workshop` folder.

You can check with:

```r
getwd()
list.files()
```

You should see folders such as `data`, `scripts`, `outputs`, `slides`, and `materials_pdf`.

## Main files

- `README_setup.md`: installation instructions
- `scripts/00_student_setup_before_workshop.R`: pre-workshop package installation and data check script
- `lesson.html`: browser version of the lesson
- `scripts/workshop_aedes_aegypti_brazil_sdm.R`: main practical script
- `data/`: backup data used in the practical
- `slides/`: workshop slides
- `materials_pdf/`: PDF handouts and reference material
