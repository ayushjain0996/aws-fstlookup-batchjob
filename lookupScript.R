library('aws.s3')
library('fst')
library('magrittr')
library('dplyr')
library(paws)

Sys.setenv(
	"AWS_ACCESS_KEY_ID" = "my-aws-access-key",
	"AWS_SECRET_ACCESS_KEY" = "my-aws-secret-access-key",
	"AWS_DEFAULT_REGION" = "us-west-2"

)

#Function to get the object key of the latest compressed fst file
getObjectKey <- function(){
	svc <- dynamodb(
		config = list(
			credentials = list(
				creds = list(
					access_key_id = "my-aws-access-key",
					secret_access_key = "my-aws-secret-access-key"
				)
			),
			region = "us-west-2"
		)
	)

	queryResult <- svc$query(
		ExpressionAttributeValues = list(
			`:v1` = list(
				S = "Active"
			),
			`:v2` = list(
				S = "yusjain/output"
			)
		),
		KeyConditionExpression = "FolderName = :v2",
		FilterExpression = "ObjectStatus = :v1",
		ProjectionExpression = "FileName",
		TableName = "yusjainJobRecords"
	)
	tsvFileName = queryResult$Items[[1]]$FileName$S
	outputKey <- substr(tsvFileName, 0, 14)
	fileExt = '.fst'
	compressedFileKey = paste0(outputKey, fileExt)
	return (compressedFileKey)
}

#Function to read the file from the output bucket given the file key.
#It prints out the output values only corresponding to the given input values
printOutputs <- function(objectKey, input1Value, input2Value){
	temporaryfile <- tempfile(fileext = ".fst")
	save_object(file = temporaryfile, object = objectKey, bucket = "yusjainoutput")
	data <- read_fst(temporaryfile)

	print("Output corresponding to given outputs:")
	result <- data %>% filter(input1 == input1Value, input2 == input2Value)
	print(result)
}

#Main function
getOutput <- function(){
	args <- commandArgs(TRUE)
	input1Value <- args[1]
	input2Value <- args[2]

	outputObjectKey <- getObjectKey()
	print("Compressed File Path:")
	print(outputObjectKey)

	printOutputs(outputObjectKey, input1Value, input2Value)
}

getOutput()

