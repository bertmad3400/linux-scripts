#!/usr/bin/python

from __future__ import unicode_literals
import youtube_dl

from tqdm import tqdm

import requests
import json
import time
import sys
import os


class youtubeDLLogger(object):
	def debug(self, msg):
		pass

	def warning(self, msg):
		pass

	def error(self, msg):
		print(msg)

wantVerboseMessages = True
wantErrorMessages = True


def VerboseMessages(message):
	if wantVerboseMessages:
		print(message)


def errorMessage(message):
	if wantErrorMessages:
		print(message)

#Blatant ripoff of stackoverflow answer
def longestSubstringFinder(string1, string2):
	answer = ""
	len1, len2 = len(string1), len(string2)
	for i in range(len1):
		match = ""
		for j in range(len2):
			if (i + j < len1 and string1[i + j] == string2[j]):
				match += string2[j]
			else:
				if (len(match) > len(answer)):
					answer = match
				match = ""
	return answer

def createFolder(foldername, path):
	print(type(path))
	print(path)
	if os.path.isdir(path + foldername):
		return path + foldername + "/"
	else:
		try:
			os.mkdir(path + foldername)
			return path + foldername + "/"
		except:
			print("FUUUUUUUUCKKKK")
			return 0


def getSpecificJSONData(JSONObject, Field1, Field2):

	JSONData = [[], []]

	maxNumber = 0

	while True:

		for element in JSONObject['Items']:
			JSONData[0].append(element[Field1])
			JSONData[1].append(element[Field2])
			maxNumber = maxNumber + 1
		try:
			JSONObject = getJSONDataFromLink(JSONObject['Paging']['Next'])
		except:
			break

	return JSONData, maxNumber


def getJSONDataFromLink(url):
	headers = {
		'user-agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0'}
	while True:
		response = requests.get(url, headers=headers)
		if response.status_code == 429:
			errorMessage('Too manu http requests, pausing (2 sec)')
			time.sleep(2)
		elif response.status_code != 200:
			errorMessage('Encountered http error, trying again')
		else:
			return json.loads(response.text)


def GetNumbersForSelection(maxNumber, titles, contentType):
	error = 0

	while True:

		print("Vælg hvilken {} du vil have: \n".format(str(contentType)))

		for i, element in enumerate(titles):
			print(str(i + 1) + ": " + element)
		print("\nSkriv et tal, en kommaseperaret liste eller 0 for at downloade dem alle sammen: ")

		seriesNumber = input().replace(" ", "").split(",")

		for i, number in enumerate(seriesNumber):
			try:
				seriesNumber[i] = int(number)
				if seriesNumber[i] == 0:
					break
				if seriesNumber[i] > maxNumber or seriesNumber[i] < 0:
					error = 2
					break
			except:
				error = 1
				break

		if error == 1:
			print("Vær venlig at skrive et eller flere tal")
			error = False

		elif error == 2:
			print("Vær venlig at skrive numre som befinder sig mellem 1 og {}".format(
				str(maxNumber)))
			error = False
		else:
			break
	if 0 in seriesNumber:
		return range(1, maxNumber + 1)
	else:
		return seriesNumber


def selectS(SData, numberOfS, contentType):
	sNumbers = GetNumbersForSelection(numberOfS, SData[1], contentType)

	downloadS = [[], []]

	for number in sNumbers:
		downloadS[0].append(SData[0][number - 1])
		downloadS[1].append(SData[1][number - 1])

	return downloadS

def checkAndRemovePrefix(titles):
	matches = titles[1]

	for i in range(2, 10):
		matches = longestSubstringFinder(matches, titles[i])

	if matches != "":
		while True:
			userInput = input("Det ligner at de fleste af afsnittene starte med \"" + matches + "\". Ønsker du at fjerne det? [y/n]: ")
			if "n" in userInput:
				VerboseMessages("Har ignoreret \"" + matches + "\".")
				break
			elif "y" in userInput:
				VerboseMessages("Fjerner \"" + matches + "\".")
				for i, element in enumerate(titles):
					if element.startswith(matches):
						titles[i] = titles[i].removeprefix(matches)
				break
			else:
				errorMessage("Forstod desværre ikke inputtet, prøv igen.")
	print("")
	return titles


def getSeriesId():
	print("Skriv navnet på serien:")

	# The name of the serie inputted by the user
	seriesName = input()

	# Max number of series used to make sure user doesn't exceed the avaiable series
	maxSeriesNumber = 1

	# Data for the different series gathered through clear text search using DR API
	differentSeries = getJSONDataFromLink(
		"https://www.dr.dk/mu-online/api/1.4/search/tv/programcards-latest-episode-with-asset/series-title/" + seriesName)

	maxSeriesNumber = len(differentSeries['Items'])

	if len(differentSeries) == 0:

		print("Der var desværre ikke nogen serie ved det navn")
		return 0

	else:

		seriesIDs, maxSeriesNumber = getSpecificJSONData(
			differentSeries, "SeriesUrn", "SeriesTitle")

		return selectS(seriesIDs, maxSeriesNumber, "serie")


def getSeasonsID(seriesID, seriesTitle):

	seasonIDs, maxSeasonsNumber = getSpecificJSONData(getJSONDataFromLink(
		"https://www.dr.dk/mu-online/api/1.4/list/view/seasons?id=" + seriesID), "Urn", "Title")

	print(seriesTitle + " har " + str(maxSeasonsNumber) + " sæsoner. ", end="")

	return selectS(seasonIDs, maxSeasonsNumber, "serie")


def getEpisodeURL(seasonID, seasonTitle):
	episodeURL, maxEpisodeNumber = getSpecificJSONData(getJSONDataFromLink(
		"https://www.dr.dk/mu-online/api/1.4/list/view/season?id=" + seasonID), "PresentationUri", "Title")

	print("https://www.dr.dk/mu-online/api/1.4/list/view/seasons?id=" + seasonID)


	#episodeURL[1] = checkAndRemovePrefix(episodeURL[1])

	VerboseMessages(seasonTitle + " har " + str(maxEpisodeNumber) + " episoder.")

	return episodeURL

def downloadVideos():
	path = "./"
	seriesID = getSeriesId()

	for i in range(0, len(seriesID[0])):
		seriesPath = createFolder(seriesID[1][i].strip().replace(" ", "-"), path)

		seasonID = getSeasonsID(seriesID[0][i], seriesID[1][i])

		for i in range(0, len(seasonID[0])):

			path = createFolder(seasonID[1][i].strip().replace(" ", "-"), seriesPath)
			episodeURL = getEpisodeURL(seasonID[0][i], seasonID[1][i])

			result = 0
			for i in tqdm(range(0, len(episodeURL[0]))):
				youtubeDLDownload(episodeURL[0][i], (path + episodeURL[1][i]).strip().replace(" ", "-"))
				result += i

def youtubeDLDownload(url, path):
	ydl_opts = {'outtmpl': (path + ".mp4"),
				'logger': youtubeDLLogger()}

	with youtube_dl.YoutubeDL(ydl_opts) as ydl:
		ydl.download([url])



downloadVideos()
