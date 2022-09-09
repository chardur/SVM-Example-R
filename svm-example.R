# clear variables, load kernlab library (which has svm), set seed
rm(list = ls())
library(kernlab)
set.seed(13)

# read the data into a data frame
df <-  read.csv('./heart.csv', header=TRUE)

# shuffle data to minimize random effects, or effects from sorted data
shuffled_df <-  df[sample(nrow(df)),]

# Split data into training, validation, and test sets

# Creating a mask using the sample function for the split
# The "mask" is the set of row indices -- for example,
# if rows 1, 5, 6, and 9 are chosen, then mask will be
# (1,5,6,9).

# 70% for training -- "sample" selects a sample of data points

mask_train = sample(nrow(shuffled_df), size = floor(nrow(shuffled_df) * 0.7))
heart_train = shuffled_df[mask_train,] # training data set

# Using the remaining data for test and validation split

remaining = shuffled_df[-mask_train, ]  # all rows except training

# Half of what's left for validation, half for test

mask_val = sample(nrow(remaining), size = floor(nrow(remaining)/2))

heart_val = remaining[mask_val,]  # validation data set
heart_test = remaining[-mask_val, ] # test data set


# set some variables that will be used in a loop
# c is going to be the cost of constraints violation (inverse of alpha in some equations)
c <- 0.000001
bestC <- 0
bestScore <- 0
scoreValues <- c()
cValues <- c()

while (c < 100000000) {
  # fit model using training set
  model <- ksvm(as.matrix(heart_train[,1:13]),
                heart_train[,14],
                type = "C-svc", # Use C-classification method
                kernel = "vanilladot", # Use simple linear kernel
                C = c,
                scaled=TRUE) # important! have ksvm scale the data for you
  
  #  compare models using validation set
  pred <- predict(model,heart_val[,1:13])
  score <- sum(pred == heart_val[,14]) / nrow(heart_val)
  
  # this will be used later to graph
  scoreValues <- append(scoreValues,score)
  cValues <- append(cValues, c)
  
  c <- c * 10 # increase c by a factor of 10 each iteration
  
  # capture the best score and c value
  if (score > bestScore){
    bestC <- c
    bestScore <- score
  }
}

# what was the best c value and score?
print(bestScore)
print(bestC)

# lets look at a graph to see the behavior
options(scipen=10)
plot((as.factor(cValues)),scoreValues, type = "o", col = "blue", xlab = "C value", ylab = "Accuracy",
     main = "Relationship of C & Accuracy")

# the best model was when c=0.01 to c=10,000, so test its actual peformance with the test data
# I chose c=0.1 as it is less computationally expensive
model <- ksvm(as.matrix(heart_train[,1:13]),
              heart_train[,14],
              type = "C-svc", # Use C-classification method
              kernel = "vanilladot", # Use simple linear kernel
              C = 0.1,
              scaled=TRUE) # have ksvm scale the data for you !!important

pred <- predict(model,heart_val[,1:13])
score <- sum(pred == heart_val[,14]) / nrow(heart_val)
score

# lets find its equation, a1..am
a <- colSums(model@xmatrix[[1]] * model@coef[[1]])
a
# calculate a0
a0 <- -model@b
a0

# optional graphs to help visualize
library(e1071)

# use the e1071 library to build a svm model
model <- svm(output~.,
             data=df, 
             type='C-classification', 
             cost=0.1, 
             kernel ="linear", 
             scale=TRUE)

# can graph two diemnsions while setting the other predictors at a constant using slice
# thall and caa
plot(model,
     data=df,
     thall ~ caa, 
     slice=list(sex=1, trtbps=130, chol=243, fbs=0.15, restecg=1, thalachh=150, exng=0, 
                oldpeak=1, slp=1, cp=1, age=55),
     color.palette =  hsv_palette())

# age and chest pain (cp)
plot(model,
     data=df,
     age ~ cp, 
     slice=list(sex=1, trtbps=130, chol=243, fbs=0.15, restecg=1, thalachh=150, exng=0, 
                oldpeak=1, slp=1, caa=0, thall=150),
     color.palette =  hsv_palette())