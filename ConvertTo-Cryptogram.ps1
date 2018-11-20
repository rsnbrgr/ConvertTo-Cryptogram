Function ConvertTo-Cryptogram {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Phrase
        )
    <#
    .SYNOPSIS
    Turns a phrase (a quote, verse, lyric, etc.) into a cryptogram puzzle

    .DESCRIPTION
    Converts a phrase to a "cryptogram" for people who like puzzles.  You solve the cryptogram by substituting a letter for each letter presented.  No letter represents more than one corresponding letter, and no letter represents itself.

    It only converts letters.  Numbers & punctuation remain as-is in the phrase.

    Logical flow of this script:
       1. Get a line of text from the user.
       2. Initialize key variables. $Encoded *must* start off as the all-lowercase version of $Decoded.
       3. Randomize the alphabet, making sure NO replacement letter matches itself (a rule of the game).
          FYI: it takes on average ~2.6 tries to randomize the alphabet so it meets this rule.
       4. Uppercase the randomized alphabet so we can do a case-sensitive swap for each lowercase letter.
       5. Swap each lowercase letter in $Encoded with its uppercase replacement.
       6. Return a PSCustomObject for the cryptogram.

    v1.00, 13 Apr 2018.  Initial release. (Rob Rosenberger)

    .EXAMPLE
    ConvertTo-Cryptogram [-Phrase] <string> [<Common Parameters>]
    ConvertTo-Cryptogram "I think, therefore I am"
    Get-Content quotes.txt | % { (ConvertTo-Cryptogram $_).Encoded }
    #>

    # Prep the decoded text for conversion
    $Decoded = $Phrase.ToLower()
    $Encoded = $Phrase.ToLower()

    #We need a sorted alphabet, of course
    $SortedAlpha = "abcdefghijklmnopqrstuvwxyz"

    # Randomize the alphabet; ensure NO replacement letter matches itself!
    $DoWhileIterations = 0
    do {$DoWhileIterations += 1

        # Shuffle the alphabet and make it uppercase
        $RandomAlpha = $SortedAlpha -split "" | Sort-Object { Get-Random }
        $RandomAlpha = -join $RandomAlpha
        $RandomAlpha = $RandomAlpha.ToUpper()

        # Is every shuffled letter -NOT itself?
        $ValidShuffle = $true  # assume true unless proven otherwise
        0..( $SortedAlpha.Length - 1 ) | % {
            if ( $SortedAlpha[$_] -eq $RandomAlpha[$_] ) {
                $ValidShuffle = $false
                }
            }
        }
     while ( -NOT $ValidShuffle )

    <#
    sorted alphabet is all lowercase
    RANDOM ALPHABET IS ALL UPPERCASE
    Replace each sorted lowercase letter with its randomized uppercase
    #>
    0..($SortedAlpha.Length - 1) | % {
        $Encoded = $Encoded -creplace $SortedAlpha[$_],$RandomAlpha[$_]
        }

    # We now have everything we need to create a Cryptogram object
    $Cryptogram = [PSCustomObject] @{
        Phrase      = $Phrase
        Encoded     = $Encoded
        SortedAlpha = $SortedAlpha
        RandomAlpha = $RandomAlpha
        Rounds      = $DoWhileIterations
        }

    # Return the Cryptogram object
    $Cryptogram
    }



Function Measure-AverageRoundsPerCryptogram
    {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [int]$TestsToPerform
        )

    <#
    .SYNOPSIS
    Calculates the average number of rounds it takes ConvertTo-Cryptogram to find a *valid* randomized alphabet.

    .DESCRIPTION
    ConvertTo-Cryptogram uses a do/while loop to randomize the alphabet so that NO letter resides in its original position.  FYI: it takes ~2.7 ±0.1 tries on average.

    Logical flow of this script:
       1. Run ConvertTo-Cryptogram with a test string, as many times as the user requested.
       2. Add up the total number of rounds it took each time to randomize the alphabet.
       3. Display the *average* number of rounds it took to randomize the alphabet.

    Some math for you:
    Tests reveal it takes on average 2.7 ±0.1 rounds to randomize the alphabet so it meets this rule.  We can shuffle the alphabet in 26! different ways, of which 25! prove valid for the game.  Doing the math, we get 4.03x10^26 total shuffles of which 1.55x10^25 prove valid for the game.


    v1.00, 13 Apr 2018.  Initial release. (Rob Rosenberger)

    .EXAMPLE
    Measure-AverageRoundsPerCryptogram [-TestsToPerform] <integer> [<Common Parameters>]
    Measure-AverageRoundsPerCryptogram 1000
    (Measure-Command { Measure-AverageRoundsPerCryptogram 1000 }).TotalSeconds
    #>

    $DoWhiles = 0
    Write-Host "Running $TestsToPerform rounds to get an average..."
    1..$TestsToPerform | % { $DoWhiles += ( ConvertTo-Cryptogram "Test" ).Rounds }

    # Display the average
    Write-Host "Average:",
               ( $DoWhiles / $TestsToPerform ),
               "rounds to find a *valid* randomized alphabet"
    }



# Did user specify a phrase on the command line?  Or must we ask the user to provide it?
if ($args.Length -gt 0) {
    $Cryptogram = ConvertTo-Cryptogram $args[0]
    }
 else {
    $Cryptogram = ConvertTo-Cryptogram ( Read-Host "What text do you want to turn into a cryptogram?`n" )
    }
# Display everything the user needs!
#Write-Host " Phrase:", $Cryptogram.Phrase
Write-Host "Encoded:", $Cryptogram.Encoded
#Write-Host " Letter:", $Cryptogram.SortedAlpha
#Write-Host " Equals:", $Cryptogram.RandomAlpha
#Write-Host ""