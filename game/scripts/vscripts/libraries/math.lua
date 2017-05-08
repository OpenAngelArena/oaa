
--[[

  taken from https://gist.github.com/Xeoncross/9511295

  Edited by chrisinajar
]]

-- This is based off an explanation and expanded math presented by Paul Bourke:
-- It takes two lines as inputs and returns true if they intersect, false if they don't.
-- If they do, ptIntersection returns the point where the two lines intersect.
-- params a, b = first line
-- params c, d = second line
-- param ptIntersection: The point where both lines intersect (if they do)
-- http://local.wasp.uwa.edu.au/~pbourke/geometry/lineline2d/
-- http://paulbourke.net/geometry/pointlineplane/
math.doLinesIntersect = function( a, b, c, d )

        -- lines are end to end
        if a.x == c.x and a.y == c.y then
          return true, a
        end
        if b.x == c.x and b.y == c.y then
          return true, b
        end
        if a.x == d.x and a.y == d.y then
          return true, a
        end
        if b.x == d.x and b.y == d.y then
          return true, b
        end
        -- parameter conversion
        local L1 = {X1=a.x,Y1=a.y,X2=b.x,Y2=b.y}
        local L2 = {X1=c.x,Y1=c.y,X2=d.x,Y2=d.y}

        -- Denominator for ua and ub are the same, so store this calculation
        local d = (L2.Y2 - L2.Y1) * (L1.X2 - L1.X1) - (L2.X2 - L2.X1) * (L1.Y2 - L1.Y1)

        -- Make sure there is not a division by zero - this also indicates that the lines are parallel.
        -- If n_a and n_b were both equal to zero the lines would be on top of each
        -- other (coincidental).  This check is not done because it is not
        -- necessary for this implementation (the parallel check accounts for this).
        if (d == 0) then
                return false
        end

        -- n_a and n_b are calculated as seperate values for readability
        local n_a = (L2.X2 - L2.X1) * (L1.Y1 - L2.Y1) - (L2.Y2 - L2.Y1) * (L1.X1 - L2.X1)
        local n_b = (L1.X2 - L1.X1) * (L1.Y1 - L2.Y1) - (L1.Y2 - L1.Y1) * (L1.X1 - L2.X1)

        -- Calculate the intermediate fractional point that the lines potentially intersect.
        local ua = n_a / d
        local ub = n_b / d

        -- The fractional point will be between 0 and 1 inclusive if the lines
        -- intersect.  If the fractional calculation is larger than 1 or smaller
        -- than 0 the lines would need to be longer to intersect.
        if (ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1) then
                local x = L1.X1 + (ua * (L1.X2 - L1.X1))
                local y = L1.Y1 + (ua * (L1.Y2 - L1.Y1))
                return true, {x=x, y=y}
        end

        return false
end
--[[

  end taken from https://gist.github.com/Xeoncross/9511295

]]

math.increase = function(x)
  x = x + 1
end

math.decrease = function(x)
  x = x - 1
end
