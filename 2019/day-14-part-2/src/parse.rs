use super::Chemical;
use nom::{
    bytes::complete::*, character::complete::*, combinator::*, multi::*, sequence::*, IResult,
};

pub(crate) type Reaction<'a> = (Vec<Chemical<'a>>, Chemical<'a>);

pub(crate) fn parse_input(text: &str) -> IResult<&str, Vec<Reaction>> {
    all_consuming(many0(terminated(reaction, multispace0)))(text)
}

fn reaction(input: &str) -> IResult<&str, Reaction> {
    pair(
        terminated(
            separated_list(terminated(tag(","), space0), chemical),
            space0,
        ),
        preceded(pair(tag("=>"), space0), chemical),
    )(input)
}

fn chemical(input: &str) -> IResult<&str, Chemical> {
    let (rest, (count, name)) = pair(
        terminated(map_res(digit1, |num: &str| num.parse::<usize>()), space1),
        alpha1,
    )(input)?;

    Ok((
        rest,
        Chemical {
            count,
            name,
        },
    ))
}
